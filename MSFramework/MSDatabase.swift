//
//  MSDatabase.swift
//  NicholsApp
//
//  Created by Michael Schloss on 6/27/15.
//  Copyright © 2015 Michael Schloss. All rights reserved.
//

import UIKit
import CoreData

///The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
@objc class MSDatabase : NSObject
{
    ///The Data Downloader object for MSDatabase
    public let dataDownloader : MSDataDownloader
    
    ///The Data Uploader object for MSDatabase
    public let dataUploader : MSDataUploader
    
    
    ///If your URL is protected by `https` or is in a password protected directory, `websiteUserName` and `websiteUserPass` are used to login to the directory
    internal static let websiteUserName = "websiteUserName"
    
    ///If your URL is protected by `https` or is in a password protected directory, `websiteUserName` and `websiteUserPass` are used to login to the directory
    internal static let websiteUserPass = "websiteUserPass"
    
    ///MySQL databases require user login and password to access the databse schema.  MSFramework assumes the login is the same as `websiteUserName` combined with this password
    internal static let databaseUserPass = "databaseUserPass"
    
    
    ///The file name of your project's CoreData model
    internal static let coreDataModelName = "coreDataModelName"
    
    
    ///The main URL providing the access to the database
    internal static let website = "website"
    
    ///The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an `SQLStatement` and returns a JSON formatted object
    internal static let readFile = "ReadFile.php"
    
    ///The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an `SQLStatement` and processes the `SQLStatement` returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
    internal static let writeFile = "WriteFile.php"
    
    
    ///A String containing any number of characters (A-Za-z0-9 & special characters) that is used to encrypt and decrypt data on device
    ///* This string is not visible outside MSFramework
    fileprivate let encryptionCode = "encryptionCode"
    
    
    ///The MSCoreDataStack object used by MSFramework.  Your application is free to pull upon this object to manage its own CoreData
    static let msCoreDataStack = MSCoreDataStack()
    
    
    ///The Downloaded Data Size formatter used by MSFramework
    let msDataSizePrinter = MSDataSizePrinter()
    
    
    ///The class that will display the Network Activity Indicator
    let msNetworkActivityIndicatorManager = MSNetworkActivityIndicatorManager()
    
    
    ///Convenience object for immediately calling the managedObjectContext
    let managedObjectContext : NSManagedObjectContext? = msCoreDataStack.managedObjectContext
    
    
    ///Set this to '1' to print out debugging logs
    static let debug = 0
    
    ///You cannot initialize this class publicly.  Use `.default` to get the singlton object of MSDatabase
    ///- SeeAlso: `default`
    fileprivate override init()
    {
        dataDownloader = MSDataDownloader()
        dataUploader = MSDataUploader()
    }
    
    
    ///Grabs the singleton object of MSDatabase.  Use this method to get the current working Database
    ///- Returns: A singleton MSDatabase object for use in your app
    static let `default` : MSDatabase = MSDatabase()
}

//MARK: - String Encrypt/Decrypt

extension MSDatabase
{
    ///Decrypts an AES 256-bit encrypted string
    ///- Parameter encryptedString: The HEX String returned from `encryptString(_:)`
    ///- Returns: A decrypted plain text string
    func decryptString(_ encryptedString: String) -> String
    {
        let data = try! (NSData().fromHexString(encryptedString) as NSData).decryptedAES256Data(usingKey: encryptionCode)
        return NSString(data: data, encoding: String.Encoding.ascii.rawValue)! as String
    }
    
    ///Encrypts a string using the AES 256-bit algorithm
    ///- Parameter decryptedString: A plain text string
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    func encryptString(_ decryptedString: String) -> String
    {
        let data : NSData = try! (decryptedString.data(using: String.Encoding.ascii)! as NSData).aes256EncryptedData(usingKey: encryptionCode) as NSData
        return data.hexRepresentation(withSpaces: false, capitals: false)
    }
    
    ///Encrypts an object using the AES 256-bit algorithm
    ///- Parameter decryptedObject: An NSObject (AnyObject in Swift) based object
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    func encryptObject(_ decryptedObject: AnyObject) -> String
    {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(decryptedObject, forKey: "object")
        archiver.finishEncoding()
        
        let encryptedData : NSData = try! data.aes256EncryptedData(usingKey: encryptionCode) as NSData
        return encryptedData.hexRepresentation(withSpaces: false, capitals: false)
    }
    
    ///Decrypts an AES 256-bit encrypted object
    ///- Parameter encryptedString: The HEX String returned from `encryptObject(_:)`
    ///- Returns: A decrypted object or nil if the string isn't an encrypted object
    func decryptObject(_ encryptedString: String) -> Any?
    {
        let data = try! (NSData().fromHexString(encryptedString) as NSData).decryptedAES256Data(usingKey: encryptionCode)
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        let object = unarchiver.decodeObject(forKey: "object")
        unarchiver.finishDecoding()
        return object
    }
}

//MARK: - Other

extension MSDatabase
{
    ///Conveience method to list all the entities' values of a property for the entity name.
    ///- Parameter property: The attribute to recall values from
    ///- Parameter entity: The entity name to search.  This method will find all instances of the entity in the Database
    func retrieveListOfProperty(_ property: String, onEntity entity: String) -> [Any]
    {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
        let fetchResults = try! managedObjectContext?.fetch(fetchRequest)
        
        var list = [Any]()
        for fetchResult in fetchResults as! [NSManagedObject]
        {
            if fetchResult.value(forKey: property) != nil
            {
                list.append(fetchResult.value(forKey: property)!)
            }
            else
            {
                list.append("")
            }
        }
        
        return list
    }
}

///Global Swift method for quick saving CoreData
func saveCoreData() throws
{
    try MSDatabase.default.managedObjectContext?.save()
}

func debugLog(_ items: Any...)
{
    guard MSDatabase.debug == 1 else { return }
    print(items)
}
