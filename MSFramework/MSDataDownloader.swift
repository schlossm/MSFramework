//
//  MSDataDownloader.swift
//  NicholsApp
//
//  Created by Michael Schloss on 6/27/15.
//  Copyright © 2015 Michael Schloss. All rights reserved.
//

import UIKit

//The Data Downloader extension for MSDatabase
//Downloads JSON data and converts it to an Array.  Has failsafes for lack of data

extension MSDatabase
{
    ///The data downloader class<br><br>MSDataDownloader connects to a `URL`, sends a `POST` request, downloads JSON formatted data, then converts that data into an NSArray and returns it via a completionHandler
    class MSDataDownloader: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate
    {
        private var downloadSession : NSURLSession!
        
        override init()
        {
            super.init()
            
            let urlSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            urlSessionConfiguration.HTTPMaximumConnectionsPerHost = 10
            urlSessionConfiguration.HTTPAdditionalHeaders = ["Accept":"application/json"]
            
            downloadSession = NSURLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: NSOperationQueue())
        }
        
        ///Downloads JSON formatted data from `website`+`readFile`.<br><br>This method will return control to your application immediately, deferring call back to `completion`. `completion` will always be ran on the main thread
        ///- Parameter sqlStatement: an MSSQL object that contains a built SQL statement
        ///- Parameter completion: A block to be called when all data has been downloaded.<br><br>`returnArray` will contain the data in iOS object format or will be `nil` is data wasn't downloaded successfully.<br><br>`error` will be nil if `returnArray` has information, otherwise will contain the corresponding error.
        func downloadDataWithSQLStatement(sqlStatement: MSSQL, completion: (returnArray : NSArray?, error: NSError?) -> Void)
        {
            let url = NSURL(string: website)!.URLByAppendingPathComponent(readFile)
            
            let postData = "Password=\(databaseUserPass)&Username=\(websiteUserName)&SQLQuery=\(sqlStatement.prettySQLStatement)".dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
            let postLength = String(postData!.length)
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.setValue(postLength, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
            request.HTTPBody = postData
            
           msNetworkActivityIndicatorManager.showIndicator()
            
            let downloadRequest = downloadSession.dataTaskWithRequest(request) { (returnData, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    msNetworkActivityIndicatorManager.hideIndicator()
                    
                    guard response?.URL?.absoluteString.hasPrefix(website) == true else { completion(returnArray: nil, error: NSError(domain: "com.Michael-Schloss.MSFramework.InvalidRedirect", code: 4, userInfo: nil)); return }
                    
                    guard error == nil else { completion(returnArray: nil, error: error); return }
                    
                    guard returnData != nil else { completion(returnArray: nil, error: NSError(domain: "com.Michael-Schloss.MSFramework.NoReturnData", code: 2, userInfo: nil)); return }
                    
                    guard let stringData = NSString(data: returnData!, encoding: NSASCIIStringEncoding) else { completion(returnArray: nil, error: NSError(domain: "com.Michael-Schloss.MSFramework.UnconvertableStringData", code: 3, userInfo: nil)); return }
                    
                    guard stringData.containsString("No Data") == false else { completion(returnArray: nil, error: NSError(domain: "com.Michael-Schloss.MSFramework.NoData", code: 1, userInfo: nil)); return }
                    
                    print("Downloaded Data Size: \(Double(returnData!.length)/1024.0) KB")
                    
                    do
                    {
                        let downloadedData = try NSJSONSerialization.JSONObjectWithData(returnData!, options: .AllowFragments) as! NSDictionary
                        
                        guard let returnArray = downloadedData["Data"] as? NSArray else
                        {
                            completion(returnArray: nil, error: NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil))
                            return
                        }
                        
                        completion(returnArray: returnArray, error: nil)
                    }
                    catch
                    {
                        completion(returnArray: nil, error: NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil));
                        return
                    }
                })
            }
            
            downloadRequest.resume()
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
