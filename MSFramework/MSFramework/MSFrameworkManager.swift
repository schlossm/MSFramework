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
 
 - Parameter success: Whether the upload failed or successed
 */
public typealias MSFrameworkUploadCompletion    = (_ success: Bool)                         -> Void

@available(*, deprecated: 10.0, renamed: "MSFrameworkManager")
public typealias MSDatabase = MSFrameworkManager

///The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
public final class MSFrameworkManager : NSObject
{
    let msCoreDataStack = MSCoreDataStack()
    let msDataSizePrinter = MSDataSizePrinter()
    
    ///The Data Downloader object for MSFramework
    public let dataDownloader : MSDataDownloader
    
    ///The Data Uploader object for MSFramework
    public let dataUploader : MSDataUploader
    
    ///The data source for `MSDatabase` contains all necessary information for MSFramework to communicate with your application's web service
    public var dataSource : MSFrameworkDataSource!
    
    
    ///MSFramework's current NSManagedObjectContext object.  Returns nil if the Persistent Store hasn't finished loading yet
    public var managedObjectContext : NSManagedObjectContext? { return dataSource != nil ? self.msCoreDataStack.managedObjectContext : nil}
    
    
    ///Set this to '1' to print out debugging logs
    static var debug = 0
    
    ///You cannot initialize this class publicly.  Use `.default` to get the singlton object of MSDatabase
    fileprivate override init()
    {
        dataDownloader = MSDataDownloader()
        dataUploader = MSDataUploader()
    }
    
    
    ///Grabs the singleton object of MSDatabase
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
        guard dataSource.encryptionCode.characters.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let iv = (string as NSString).substring(to: 16)
        guard var data = (string as NSString).substring(from: 16).hexadecimal else { return string }
        
        let aes = try! AES(key: dataSource.encryptionCode, iv: iv)
        data = try! Data(bytes: aes.decrypt(data.bytes))
        return NSString(data: data, encoding: String.Encoding.ascii.rawValue)! as String
    }
    
    ///Encrypts a string using an AES 256-bit algorithm
    ///- Parameter string: A plain text string
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    public func encrypt(string: String) -> String
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        guard dataSource.encryptionCode.characters.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let data = string.data(using: String.Encoding.ascii)! as Data
        
        let aes = try! AES(key: dataSource.encryptionCode, iv: dataSource.iv)
        return try! dataSource.iv + Data(bytes: aes.encrypt(data.bytes)).hexEncoded
    }
    
    ///Encrypts an object using an AES 256-bit algorithm
    ///- Parameter object: An `NSObject` (`Any` in Swift) object
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    public func encrypt(object: Any) -> String
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        guard dataSource.encryptionCode.characters.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(object, forKey: "object")
        archiver.finishEncoding()
        
        let aes = try! AES(key: dataSource.encryptionCode, iv: dataSource.iv)
        return try! dataSource.iv + Data(bytes: aes.encrypt((data as Data).bytes)).hexEncoded
    }
    
    ///Decrypts an AES 256-bit encrypted object
    ///- Parameter encryptedString: The HEX String returned from `encrypt(object:)`
    ///- Returns: A decrypted object or nil if the string isn't an encrypted object
    public func decrypt(object: String) -> Any?
    {
        guard dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        guard dataSource.encryptionCode.characters.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let iv = (object as NSString).substring(to: 16)
        guard var data = (object as NSString).substring(from: 16).hexadecimal else { return object }
        
        let aes = try! AES(key: dataSource.encryptionCode, iv: iv)
        data = try! Data(bytes: aes.decrypt(data.bytes))
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        let object = unarchiver.decodeObject(forKey: "object")
        unarchiver.finishDecoding()
        return object
    }
}

//MARK: - Other

extension MSFrameworkManager
{
    /**
     Conveience method to list all the entities' values of an attribute for the entity name.
     
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
