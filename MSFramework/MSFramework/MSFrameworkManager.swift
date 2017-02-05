//
//  MSFrameworkManager.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import CoreData

/**
 The download Completion Handler
 
 - Parameter returnData: The returned JSON Serialized data.  This data is usually an array of Dictionaries.
 - Parameter error: An error when downloaded, if any
 */
public typealias MSFrameworkDownloadCompletion  = (_ returnData: [Any]?,_ error: Error?)    -> Void

/**
 The upload Completion Handler
 
 - Parameter success: Whether the upload failed or succeeded
 */
public typealias MSFrameworkUploadCompletion    = (_ success: Bool)                         -> Void

@available(*, deprecated: 10.0, renamed: "MSFrameworkManager")
public typealias MSDatabase = MSFrameworkManager

///The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
public final class MSFrameworkManager : NSObject
{
    let msCoreDataStack = MSCoreDataStack()
    let msDataSizePrinter = MSDataSizePrinter()
    
    fileprivate var iv = AES.randomIV(16)
    
    ///The Data Downloader object for MSFramework
    public let dataDownloader : MSDataDownloader
    
    ///The Data Uploader object for MSFramework
    public let dataUploader : MSDataUploader
    
    ///The data source for `MSDatabase` contains all necessary information for MSFramework to communicate with your application's web service
    public var dataSource : MSFrameworkDataSource!
        {
        didSet
        {
            if dataSource.coreDataModelName != ""
            {
                msCoreDataStack.load()
            }
        }
    }
    
    
    ///MSFramework's current NSManagedObjectContext object.  Returns nil if the Persistent Store hasn't finished loading yet
    public var managedObjectContext : NSManagedObjectContext? { return dataSource != nil ? self.msCoreDataStack.managedObjectContext : nil}
    
    
    ///Set this to '1' to print out debugging logs
    fileprivate static var debug = 0
    
    ///You cannot initialize this class publicly.  Use `.default` to get the singlton object of MSDatabase
    fileprivate override init()
    {
        dataDownloader = MSDataDownloader()
        dataUploader = MSDataUploader()
    }
    
    
    ///Grabs the singleton object of MSFrameworkManager
    public static let `default` : MSFrameworkManager = MSFrameworkManager()
    
    ///Call this method to enable debugging mode
    public func enableDebug()
    {
        MSFrameworkManager.debug = 1
    }
}

//MARK: - String Encrypt/Decrypt

extension MSFrameworkManager
{
    ///Decrypts an AES 256-bit encrypted string
    ///- Parameter string: The HEX String returned from `encrypt(string:)`
    ///- Returns: A decrypted plain text string
    public func decrypt(string: String) -> String
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        
        let encryptionCode = (string as NSString).substring(to: 64)
        let iv = (string as NSString).substring(with: NSMakeRange(64, 32))
        guard let data = (string as NSString).substring(from: 96).hexadecimal else { return string }
        
        let ivChars = Array(iv.characters)
        let convertedIV = stride(from: 0, to: ivChars.count, by: 2).map() {
            UInt8.init(strtoul(String(ivChars[$0 ..< min($0 + 2, ivChars.count)]), nil, 16))
        }
        
        let encChars = Array(encryptionCode.characters)
        let convertedEnc = stride(from: 0, to: encChars.count, by: 2).map() {
            UInt8.init(strtoul(String(encChars[$0 ..< min($0 + 2, encChars.count)]), nil, 16))
        }
        
        let aes = try! AES(key: convertedEnc, iv: convertedIV, blockMode: .CBC, padding: PKCS7())
        let decryptedData = try! Data(bytes: aes.decrypt(data.bytes))
        return String.init(data: decryptedData, encoding: .ascii)!
    }
    
    ///Encrypts a string using an AES 256-bit algorithm
    ///- Parameter string: A plain text string
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    public func encrypt(string: String) -> String
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        
        let encryptionCode = dataSource.encryptionCode
        guard encryptionCode.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let data = string.data(using: .ascii)!
        let aes = try! AES(key: encryptionCode, iv: iv, blockMode: .CBC, padding: PKCS7())
        return try! encryptionCode.toHexString() + iv.toHexString() + Data(bytes: aes.encrypt(data.bytes)).bytes.toHexString()
    }
    
    ///Encrypts an object using an AES 256-bit algorithm
    ///- Parameter object: An `NSObject` (`Any` in Swift) object
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    public func encrypt(object: Any) -> String
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        
        let encryptionCode = dataSource.encryptionCode
        guard encryptionCode.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(object, forKey: "object")
        archiver.finishEncoding()
        
        let aes = try! AES(key: encryptionCode, iv: iv, blockMode: .CBC, padding: PKCS7())
        return try! encryptionCode.toHexString() + iv.toHexString() + Data(bytes: aes.encrypt((data as Data).bytes)).bytes.toHexString()
    }
    
    ///Decrypts an AES 256-bit encrypted object
    ///- Parameter object: The HEX String returned from `encrypt(object:)`
    ///- Returns: A decrypted object or nil if the string isn't an encrypted object
    public func decrypt(object: String) -> Any?
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        
        let encryptionCode = (object as NSString).substring(to: 64)
        let iv = (object as NSString).substring(with: NSMakeRange(64, 32))
        guard let data = (object as NSString).substring(from: 96).hexadecimal else { return object }
        
        let ivChars = Array(iv.characters)
        let convertedIV = stride(from: 0, to: ivChars.count, by: 2).map() {
            UInt8.init(strtoul(String(ivChars[$0 ..< min($0 + 2, ivChars.count)]), nil, 16))
        }
        
        let encChars = Array(encryptionCode.characters)
        let convertedEnc = stride(from: 0, to: encChars.count, by: 2).map() {
            UInt8.init(strtoul(String(encChars[$0 ..< min($0 + 2, encChars.count)]), nil, 16))
        }
        
        let aes = try! AES(key: convertedEnc, iv: convertedIV, blockMode: .CBC, padding: PKCS7())
        let decrypted = try! Data(bytes: aes.decrypt(data.bytes))
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: decrypted)
        let object = unarchiver.decodeObject(forKey: "object")
        unarchiver.finishDecoding()
        return object
    }
}

//MARK: - Other

extension MSFrameworkManager
{
    /**
     Conveience method to list all the entities' values of an attribute for the entity name
     
     - Parameter attribute: The attribute to recall values from
     - Parameter entity: The entity name to search in.  Looks only at on-device stored data
     */
    public func retrieveList(attribute: String, onEntity entity: String) -> [Any]
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
        let fetchResults = try! managedObjectContext?.fetch(fetchRequest)
        
        var list = [Any]()
        for fetchResult in fetchResults as! [NSManagedObject]
        {
            list.append(fetchResult.value(forKey: attribute) ?? "")
        }
        
        return list
    }
}

///Global Swift method for quick saving CoreData
public func saveCoreData() throws
{
    try MSFrameworkManager.default.managedObjectContext?.save()
}

func debugLog(_ items: Any...)
{
    guard MSFrameworkManager.debug == 1 else { return }
    print(items)
}
