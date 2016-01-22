//
//  MSDataUploader.swift
//  NicholsApp
//
//  Created by Michael Schloss on 6/27/15.
//  Copyright © 2015 Michael Schloss. All rights reserved.
//

import UIKit

//The Data Uploader extension for MSDatabase
//Uploads an SQL statement and returns a bool depending on whether or not the SQL statement was successfully ran

extension MSDatabase
{
    ///The data uploader class<br><br>MSDataUploader connects to a `URL`, sends a `POST` request containing the SQL statement to run, downloads **Success** or **Failure**, and returns a bool based upon that
    class MSDataUploader: NSObject, NSURLSessionDelegate
    {
        private var uploadSession : NSURLSession!
        
        override init()
        {
            super.init()
            
            let urlSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            urlSessionConfiguration.HTTPMaximumConnectionsPerHost = 10
            urlSessionConfiguration.HTTPAdditionalHeaders = ["Accept":"application/json"]
            
            uploadSession = NSURLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: NSOperationQueue())
        }
        
        ///Uploads an SQL statement to `website`+`writeFile`.<br><br>This method will return control to your application immediately, deferring call back to `completion`.  `completion` will always be ran on the main thread
        ///- Parameter sqlStatement: an MSSQL object that contains a built SQL statement
        ///- Parameter completion: A block to be called when `website`+`writeFile` has returned either **Success** or **Failure**.  The boolean will reflect which word was found
        func uploadDataWithSQLStatement(sqlStatement: MSSQL, completion: (Bool) -> Void)
        {
            let url = NSURL(string: website)!.URLByAppendingPathComponent(writeFile)
            
            let postData = "Password=\(databaseUserPass)&Username=\(websiteUserName)&SQLQuery=\(sqlStatement.prettySQLStatement)".dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
            let postLength = String(postData!.length)
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.setValue(postLength, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
            request.HTTPBody = postData
            
            msNetworkActivityIndicatorManager.showIndicator()
            
            let uploadRequest = uploadSession.dataTaskWithRequest(request) { (returnData, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    msNetworkActivityIndicatorManager.hideIndicator()
                    
                    guard response?.URL?.absoluteString.hasPrefix(website) == true else { completion(false); return }
                    guard error == nil && returnData != nil else { completion(false); return }
                    guard let stringData = NSString(data: returnData!, encoding: NSASCIIStringEncoding) else { completion(false); return }
                    guard stringData.containsString("Success") else { completion(false); return }
                    
                    completion(true)
                })
            }
            
            uploadRequest.resume()
        }
        
        //MARK: - NSURLSessionDelegate
        
        func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
        {
            let credential = NSURLCredential(user: websiteUserName, password: websiteUserPass, persistence: NSURLCredentialPersistence.ForSession)
            
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, credential)
        }
        
        func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
        {
            let credential = NSURLCredential(user: websiteUserName, password: websiteUserPass, persistence: NSURLCredentialPersistence.ForSession)
            
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, credential)
        }
    }
}