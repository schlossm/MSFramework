//
//  MSDatabaseDataSource.swift
//  MSFramework2
//
//  Created by Michael Schloss on 12/24/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

@available(*, deprecated: 10.0, renamed: "MSFrameworkDataSource")
public typealias MSDatabaseDataSource = MSFrameworkDataSource

public protocol MSFrameworkDataSource
{
    ///The username to log into a protected directory.  This value is only used if needed.
    var websiteUserName     : String { get }
    
    ///The password to log into a protected directory.  This value is only used if needed.
    var websiteUserPass     : String { get }
    
    ///MySQL databases require user login and password to access the databse schema.  MSFramework assumes the login `websiteUserName` combined with this password
    var databaseUserPass    : String { get }
    
    
    ///The file name of your project's CoreData model
    var coreDataModelName   : String { get }
    
    
    ///The base URL the application will be communicating with
    var website             : String { get }
    
    /**
     The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and returns a JSON formatted object
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
     */
    var readFile            : String { get }
    
    /**
     The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and processes the SQL statement returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
     */
    var writeFile           : String { get }
    
    
    ///A String containing 32 characters ([A-Za-z0-9] & special characters) that is used to encrypt and decrypt data on device
    var encryptionCode      : String { get }
    
    //The Initialization Vector for encryption.  Should be exactly 16 characters in length
    var iv                  : String { get }
}
