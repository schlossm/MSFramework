#MSFramework
######Version 2.0

iOS Framework for pulling JSON data using `POST` from a MySQL database and storing it to CoreData

---

**PLEASE READ**: MSFramework is written in Swift 3, which requires Xcode 8+.  MSFramework is _**not**_ compatible with Objective-C, due to it using internal Swift types that are currently unrepresentable in Objective-C.

---

MSFramework is compatible with macOS, iOS, tvOS, and watchOS

##Installation
1. Drag the `MSFramework.xcodeproj` file into your Xcode project
2. Under your project target's General tab, click on the `+` in the **Embedded Frameworks** section
3. Click the `MSFramework.framework` Framework and press add
4. In any file you wish to use MSFramework, add this header:
	* Swift: `import MSFramework`
	* Obj-C: `@import MSFramework;`  **NOTE:** As of right now, MSFramework does not import into Objective-C properly.  Please raise an issue post if you manage to solve this before I can.

##Use
MSFramework is intended to be used opaquely.  While the source code is yours to tamper with, you should not unless you know what you're doing.

**Swift**

```Swift
class ProjectDatabase : [...,] MSFrameworkDataSource
{
	var msFramework = MSFrameworkManager.default
	msFramework.dataSource = self
	...
}
```

MSFramework is initialized with the MSFrameworkManager class.  the `default` class property gives you access to the singleton object for MSFramework.

MSFramework requires a data source that complies with the `MSFrameworkDataSource` protocol.  This protocol contains several variables that MSFramework will use to communicate with your web service.  See `MSFrameworkDataSource` for more info.

##SQL

MSFramework has its own SQL class: `MSSQL`. This class contains all SQL `SELECT`, `FROM`, `JOIN`, `INSERT`, `UPDATE`, `ORDER BY`, and `WHERE` combinations.  This class is overload and security safe, and will automatically sanitize its input, throwing catchable errors when it encounters illegal text. MSFramework uses this class for processing SQL queries up to a database.

See the `MSSQL` class for more info.

**NOTE**: `MSSQL` currently does not allow nested SQL statements.  This will come in the future.

##Classes

MSFramework contains the following classes

* `MSFrameworkManager`
	* The main class for MSFramework.  By using this class you can interact with the full scope of MSFramework
* `MSDataUploader`
	* The data uploader class<br>MSDataUploader connects to a `URL`, sends a `POST` request containing the SQL statement to run, downloads **Success** or **Failure**, and returns a Bool based upon that
* `MSDataDownloader`
	* The data downloader class<br>MSDataDownloader connects to a `URL`, sends a `POST` request, downloads JSON formatted data, then converts that data into an NSArray and returns it via a completionHandler
* `MSSQL`
	* Class for building an SQL formatted statement
	* There are several enums and structs for use when constructing SQL statements
* `MSCoreDataStack`
	* The CoreData class for MSDatabase
* `MSFrameworkDataSource`
	* Contains variables that MSFramework will call upon when querying your web service.  If this protocol is not implemented, MSFramework will terminate your run 
* `CryptoSwift`
	* A Swift Framework for encrypting data using an AES 256-bit algorithm.  Credit goes to [Marcin Krzyzanowski] (https://github.com/krzyzanowskim/CryptoSwift)


##Variables
MSFramework has several variables that must be implemented when complying with `MSFrameworkDataSource`

* `website`: The base URL the application will be communicating with

* `readFile`: The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and returns a JSON formatted object
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
* `writeFile`: The relative path to a file in the URL that takes a `POST` object containing `databaseUserPass`, `websiteUserName`, and an SQL statement and processes the SQL statement returning **"Success"** if the SQLStatement is successfully ran or **"Failure"** if it fails
     
     This file should take in three parameters for the `POST`:
     * `Password`
     * `Username`
     * `SQLStatement`
* `websiteUserName`: The username to log into a protected directory.  This value is only used if needed.
* `websiteUserPass`: The password to log into a protected directory.  This value is only used if needed.
* `databaseUserPass`: MySQL databases require user login and password to access the databse schema.  MSFramework assumes the login `websiteUserName` combined with this password
* `coreDataModelName`: The file name of your project's CoreData model
* `encryptionCode`: A String containing 32 characters ([A-Za-z0-9] & special characters) that is used to encrypt and decrypt data on device
* `iv`: The initialization vector for MSFramework's encryption