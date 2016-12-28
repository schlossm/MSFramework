//
//  MSDatabaseDataSource.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/24/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

@available(*, deprecated: 10.0, renamed: "MSFrameworkDataSource")
public typealias MSDatabaseDataSource = MSFrameworkDataSource

/**
 Used by MSFamework to covert a table and its attributes to its corresponding CoreData entities and attributes
 
 One instance per table/entity.  Required to be a `class` to maintain compatibility with Objective-C
 */
@objc public class MySQLToCoreData : NSObject
{
    @objc var databaseTableName : String!
    @objc var coreDataTableName : String!
    
    /**
     Used by MSFramework to convert downloaded table attributes to CoreData Entity's attributes.
     
     **Format**
     
     
     `["downloadedAName":"CDAttributeName"]`
     */
    @objc var attributesToCDAttributes : [String : String]!
}

@objc public protocol MSFrameworkDataSource
{
    ///The username to log into a protected directory.  This value is only used if needed.
    @objc optional var websiteUserName     : String { get }
    
    ///The password to log into a protected directory.  This value is only used if needed.
    @objc optional var websiteUserPass     : String { get }
    
    ///MySQL databases require user login and password to access the databse schema.  MSFramework assumes the login `websiteUserName` combined with this password
    @objc optional var databaseUserPass    : String { get }
    
    
    ///The file name of your project's CoreData model
    @objc var coreDataModelName   : String { get }
    
    
    ///The base URL the application will be communicating with
    @objc var website             : String { get }
    
    /**
     The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and returns a JSON formatted object
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
     */
    @objc var readFile            : String { get }
    
    /**
     The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and processes the SQL statement returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
     */
    @objc var writeFile           : String { get }
    
    
    ///A String containing 32 characters ([A-Za-z0-9] & special characters) that is used to encrypt and decrypt data on device
    @objc var encryptionCode      : String { get }
    
    ///The Initialization Vector for encryption.  Should be exactly 16 characters in length
    @objc var iv                  : String { get }
    
    /**
     Used by MSFramework to convert between downloaded MySQL table structure and internal CoreData structure
     
     MSFramework only calls upon this variable when it cannot automatically determine the CoreData table name.
     */
    @objc optional var databaseToCoreDataInfo  : [MySQLToCoreData] { get }
}
