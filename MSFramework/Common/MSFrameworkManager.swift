//
//  MSFrameworkManager.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import CoreData
import CryptoSwift

/**
 The download completion handler
 
 - Parameter returnData: The returned JSON Serialized data.  This data is usually [[:]].
 - Parameter error: An error when downloaded, if any
 */
public typealias MSFrameworkDownloadCompletion = (_ returnData: [Any]?, _ error: Error?) -> Void

/**
 The upload completion handler
 
 - Parameter success: Whether the upload failed or succeeded
 */
public typealias MSFrameworkUploadCompletion = (_ success: Bool) -> Void

@available(*, unavailable, renamed: "MSFrameworkManager")
public typealias MSDatabase = MSFrameworkManager

///The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
public final class MSFrameworkManager
{
    ///Grabs the singleton object of MSFrameworkManager
    public static let `default` : MSFrameworkManager = MSFrameworkManager()
    
    let msCoreDataStack = MSCoreDataStack()
    let msDataSizePrinter = MSDataSizePrinter()
    
    fileprivate var iv = AES.randomIV(16)
    
    ///The Data Downloader object for MSFramework
    public let dataDownloader = MSDataDownloader()
    
    ///The Data Uploader object for MSFramework
    public let dataUploader = MSDataUploader()
    
    lazy var defaultSession : URLSessionConfiguration = {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 10
        urlSessionConfiguration.httpAdditionalHeaders = ["Accept":"application/json"]
        return urlSessionConfiguration
    }()
    
    ///The data source for `MSDatabase` contains all necessary information for MSFramework to communicate with your application's web service
    public var dataSource : MSFrameworkDataSource?
    {
        didSet
        {
            guard let dataSource = dataSource else { return }
            encryptionCodeIsChanging = dataSource.encryptionCode != dataSource.encryptionCode
            if dataSource.coreDataModelName != ""
            {
                msCoreDataStack.load()
            }
        }
    }
    
    fileprivate var encryptionCodeIsChanging = false
    
    ///MSFramework's current NSManagedObjectContext object.  Returns nil if the Persistent Store hasn't finished loading yet
    public var managedObjectContext : NSManagedObjectContext? { return msCoreDataStack.managedObjectContext }
    
    internal static var debug = false
    
    ///You cannot initialize this class publicly.  Use `.default` to get the singlton object of MSDatabase
    private init() { }
    
    ///Call this method to enable debugging mode
    public func enableDebug() { MSFrameworkManager.debug = true }
}

//MARK: - String Encrypt/Decrypt

extension MSFrameworkManager
{
    ///Encrypts a string using an AES 256-bit algorithm
    ///- Parameter string: A plain text string
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    public func encrypt(string: String, salt: String) -> String?
    {
        let password : Array<UInt8> = Array(string.utf8)
        let salt : Array<UInt8> = Array(salt.utf8)
        
        do
        {
            let hash = try PKCS5.PBKDF2(password: password, salt: salt, iterations: 4096, variant: .sha256).calculate()
            return Data(bytes: hash).base64EncodedString()
        }
        catch
        {
            print(error)
            return nil
        }
    }
    
    ///Encrypts an object using an AES 256-bit algorithm
    ///- Parameter object: An `NSObject` (`Any` in Swift) object
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    public func encrypt(object: Any) -> String
    {
        guard let dataSource = dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        
        let encryptionCode = dataSource.encryptionCode
        guard encryptionCode.count == 32 else { fatalError("The encryption code MUST be 32 characters.") }
        
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(object, forKey: "object")
        archiver.finishEncoding()
        
        let aes = try! AES(key: encryptionCode, iv: iv, blockMode: .CBC, padding: .pkcs7)
        return try! (encryptionCodeIsChanging ? encryptionCode.toHexString() : "") + iv.toHexString() + Data(bytes: aes.encrypt((data as Data).bytes)).bytes.toHexString()
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
    guard MSFrameworkManager.debug else { return }
    print(items)
}
