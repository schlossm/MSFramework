//
//  MSDatabase.swift
//  NicholsApp
//
//  Created by Michael Schloss on 6/27/15.
//  Copyright © 2015 Michael Schloss. All rights reserved.
//

import UIKit
import CoreData

private var MSDatabaseInstance : MSDatabase!


///The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
@objc class MSDatabase : NSObject
{
    ///The DataDownloader object for MSDatabase
    internal let dataDownloader : MSDataDownloader
    ///The DataUploader object for MSDatabase
    internal let dataUploader : MSDataUploader
    
    ///If your URL is protected by `https` or is in a password protected directory, `websiteUserName` and `websiteUserPass` are used to login to the directory
    internal static let websiteUserName = "XXXX"
    ///If your URL is protected by `https` or is in a password protected directory, `websiteUserName` and `websiteUserPass` are used to login to the directory
    internal static let websiteUserPass = "XXXX"
    
    ///MYSQL databases require user login and password to access the databse schema.  MSFramework assumes the login name is the same as `websiteUserName` combined with the password
    internal static let databaseUserPass = "XXXX"
    
    ///The file name of your project's CoreData model
    internal static let coreDataModelName = "XXXX"
    
    ///The main URL providing the access to the database
    internal static let website = "XXXX"
    ///The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an `SQLStatement` and returns a JSON formatted object
    internal static let readFile = "XXXX"
    ///The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an `SQLStatement` and processes the `SQLStatement` returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
    internal static let writeFile = "XXXX"
    
    ///A String containing any number of characters (A-Z, a-z, 0-9 & special characters) that is used to encrypt and decrypt data on device
    ///* This string is not visible outside MSFramework
    private let encryptionCode = "XXXX"
    
    ///The MSCoreDataStack object used by MSFramework.  Your application is free to pull upon this object to manage its own CoreData
    internal let msCoreDataStack = MSCoreDataStack()
    
    internal static let msNetworkActivityIndicatorManager = MSNetworkActivityIndicatorManager()
    
    ///Convenience object for immediately calling the managedObjectContext
    internal var managedObjectContext : NSManagedObjectContext
        {
        get
        {
            return msCoreDataStack.managedObjectContext
        }
    }
    
    ///You cannot initialize this class publicly.  Use `sharedDatabase()` to get the singlton object of MSDatabase
    ///- SeeAlso: `sharedDatabase()`
    @available(*, unavailable)
    override init()
    {
        dataDownloader = MSDataDownloader()
        dataUploader = MSDataUploader()
    }
    
    private init(fromSharedClassClass: String?)
    {
        dataDownloader = MSDataDownloader()
        dataUploader = MSDataUploader()
    }
    
    ///Grabs the singleton object of MSDatabase.  Use this method to get the current working Database
    ///- Returns: A singleton MSDatabase object for use in your app
    class func sharedDatabase() -> MSDatabase
    {
        if MSDatabaseInstance == nil
        {
            MSDatabaseInstance = MSDatabase(fromSharedClassClass: nil)
        }
        
        return MSDatabaseInstance
    }
}

//MARK: - String Encrypt/Decrypt

extension MSDatabase
{
    ///Decrypts an AES 256-bit encrypted string
    ///- Parameter encryptedString: The HEX String returned from `encryptString(_:)`
    ///- Returns: A decrypted plain text string
    func decryptString(encryptedString: String) -> String
    {
        let data = try! NSData().dataFromHexString(encryptedString).decryptedAES256DataUsingKey(encryptionCode)
        return NSString(data: data, encoding: NSASCIIStringEncoding)! as String
    }
    
    ///Encrypts a string using the AES 256-bit algorithm
    ///- Parameter decryptedString: A plain text string
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    func encryptString(decryptedString: String) -> String
    {
        let data = try! decryptedString.dataUsingEncoding(NSASCIIStringEncoding)!.AES256EncryptedDataUsingKey(encryptionCode)
        return data.hexRepresentationWithSpaces(false, capitals: false)
    }
    
    ///Encrypts an object using the AES 256-bit algorithm
    ///- Parameter decryptedObject: An NSObject (AnyObject in Swift) based object
    ///- Returns: The HEX representation from an AES 256-bit encrypted object
    func encryptObject(decryptedObject: AnyObject) -> String
    {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        archiver.encodeObject(decryptedObject, forKey: "object")
        archiver.finishEncoding()
        
        let encryptedData = try! data.AES256EncryptedDataUsingKey(encryptionCode)
        return encryptedData.hexRepresentationWithSpaces(false, capitals: false)
    }
    
    ///Decrypts an AES 256-bit encrypted object
    ///- Parameter encryptedString: The HEX String returned from `encryptObject(_:)`
    ///- Returns: A decrypted object or nil if the string isn't an encrypted object
    func decryptObject(encryptedString: String) -> AnyObject?
    {
        let data = try! NSData().dataFromHexString(encryptedString).decryptedAES256DataUsingKey(encryptionCode)
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        let object = unarchiver.decodeObjectForKey("object")
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
    func retrieveListOfProperty(property: String, onEntity entity: String) -> [AnyObject]
    {
        let fetchRequest = NSFetchRequest(entityName: entity)
        let fetchResults = try! msCoreDataStack.managedObjectContext.executeFetchRequest(fetchRequest)
        
        var list = [AnyObject]()
        for fetchResult in fetchResults as! [NSManagedObject]
        {
            if fetchResult.valueForKey(property) != nil
            {
                list.append(fetchResult.valueForKey(property)!)
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
    try MSDatabase.sharedDatabase().managedObjectContext.save()
}
