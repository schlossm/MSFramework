//
//  MSFrameworkDataSource.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/24/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

@available(*, deprecated: 10.0, renamed: "MSFrameworkDataSource")
public typealias MSDatabaseDataSource = MSFrameworkDataSource

/**
 Used by MSFamework to covert a MySQL table and its attributes to its corresponding CoreData entities and attributes
 
 **One instance per table-entity pair**
 */
public struct MySQLToCoreData
{
    /**
     The table name in the web service's MySQL database
     */
    public var databaseTableName : String
    /**
     The corresponsing entity's name in the application's CoreData model
     */
    public var coreDataTableName : String
    
    /**
     Used by MSFramework to convert MySQL Table attributes to CoreData Entity attributes.
     
     **Format**
     
     `["MySQLAttributeName":"CoreDataAttributeName"]`
     - Note: The `CoreDataAttributeName` is case sensitive!
     */
    public var attributesToCDAttributes : [String : String]
}

/**
 MSFramework's Data Source
 
 The data source contains
 * Login information for the MySQL database (and website if password protected directory is enabled)
 * Website URLs to reach your web service
 * Encryption code and IV for AES encryption
 * An array of `MySQLToCoreData` objects that allow MSFramework to auto-save downloaded data
 */
public protocol MSFrameworkDataSource
{
    ///The username to log into a protected directory. This value is only used if needed.
    var websiteUserName         : String { get }
    
    ///The password to log into a protected directory. This value is only used if needed.
    var websiteUserPass         : String { get }
    
    ///MySQL databases require user login and password to access the databse schema. MSFramework assumes the login `websiteUserName` combined with this password
    var databaseUserPass        : String { get }
    
    ///The file name of your project's CoreData model
    var coreDataModelName       : String { get }
    
    ///The base URL the application will be communicating with
    var website                 : String { get }
    
    /**
     The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and returns a JSON formatted object
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
     */
    var readFile                : String { get }
    
    /**
     The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and processes the SQL statement returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
     */
    var writeFile               : String { get }
    
    ///Used to encrypt and decrypt data on device
    var encryptionCode          : Array<UInt8> { get }
    
    /**
     Used by MSFramework to convert between downloaded a MySQL table structure and the application's internal CoreData structure
     
     MSFramework uses a custom high-level API to attempt to automatically find the CoreData information.  If it cannot, MSFramework will call upon this variable to retrieve the right information
     */
    var databaseToCoreDataInfo  : [MySQLToCoreData] { get }
    var wantsCustomCDControl    : Bool { get }
}
