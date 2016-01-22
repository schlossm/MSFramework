#MSFramework
iOS Framework for pulling JSON data using `POST` from a MYSQL database and storing it to CoreData

MSFramework is written in Swift 2, which requires Xcode 7+.  MSFramework is fully compatible with Objective-C

MSFramework is not compatible with OS X

##Installation
Drag the `MSFramework` folder into your Xcode project, adding all necessary files to your project's target.

- **NOTE:** This project contains a pre-built Objective-C Bridging Header file.  If you already have one in your project, import `"BridgingHeader.h"` into your bridging header.  If you do not already have a brigding header, add `BridgingHeader.h` to your Build Settings > Objective-C Bridging Header

##Use
Treat MSFramework as an opaque class

Swift

```Swift
class ProjectDatabase
{
	var msDatabaseObject = MSDatabase.sharedDatabase()
	...
}
```

Objective-C

```Objective-C
#import <ProjectName-Swift.h>

@interface ProjectDatabase : NSObject

	@property (nonatomic, strong) MSDatabase *msDatabaseObject;
	
	...
@end
	
-------------

@implementation ProjectDatabase : NSObject
	
	- (id) init
	{
		msDatabaseObject = [MSDatabase sharedDatabase];
		...
	}
	...
@end
```

##SQL

MSFramework has its own SQL class, `MSSQL`, that contains many of the common SQL statements as easy methods.  MSFramework uses this class for processing SQL queries up to a database.  Please refer to MSFramework.`MSSQL` for more information

##Classes

MSFramework contains the following classes

* MSFramework.`MSDatabase`
	* The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
* MSFramework.`MSDataUploader`
	* The data uploader class<br>MSDataUploader connects to a `URL`, sends a `POST` request containing the SQL statement to run, downloads **Success** or **Failure**, and returns a bool based upon that
* MSFramework.`MSDataDownloader`
	* The data downloader class<br>MSDataDownloader connects to a `URL`, sends a `POST` request, downloads JSON formatted data, then converts that data into an NSArray and returns it via a completionHandler
* MSFramework.`MSSQL`
	* Class for building an SQL formatted statement
* MSFramework.`MSCoreDataStack`
	* The CoreData class for MSDatabase
* MSFramework.`MSNetworkActivityIndicatorManager`
	* Displays the Network Activity Indicator when `showIndicator()` is called, and hides when `hideIndicator()` is called.<br>This class keeps track of the number of calls to prevent premature dismissing of the network indicator<br>**NOTE:** It is recommended your app uses this class to manage the Network Activity Indicator across the entire application as this class can prematurely dismiss the Network Activity Indicator
* MSFramework.`MSEncryption`
	* The Objective-C Framework for encrypting data using an AES 256-bit algorithm


##Variables
MSFramework has several variables for easy access and use.  These are located inside the main class `MSDatabase`

* `website`: The main URL providing the access to the database


* `readFile`: The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an `SQLStatement` and returns a JSON formatted object
* `writeFile`: The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an `SQLStatement` and processes the `SQLStatement` returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
* `websiteUserName`: If your URL is protected by `https` or is in a password protected directory, `websiteUserName` and `websiteUserPass` are used to login to the directory
* `websiteUserPass`: If your URL is protected by `https` or is in a password protected directory, `websiteUserName` and `websiteUserPass` are used to login to the directory
* `databaseUserPass`: MYSQL databases require user login and password to access the databse schema.  MSFramework assumes the login name is the same as `websiteUserName` combined with the password `databaseUserPass`
* `coreDataModelName`: The file name of your project's CoreData model
* `encryptionCode`: A String containing any number of characters (A-Z, a-z, 0-9 & special characters) that is used to encrypt and decrypt data on device
	* This string is not visible outside MSFramework