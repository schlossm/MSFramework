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
    ///The data uploader class
    ///
    ///MSDataUploader connects to a `URL`, sends a `POST` request containing the SQL statement to run, downloads **Success** or **Failure**, and returns a bool based upon that
    class MSDataUploader: NSObject, URLSessionDelegate
    {
        private var uploadSession : Foundation.URLSession!
        
        override init()
        {
            super.init()
            
            let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.httpMaximumConnectionsPerHost = 10
            urlSessionConfiguration.httpAdditionalHeaders = ["Accept":"application/json"]
            
            uploadSession = Foundation.URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: OperationQueue())
        }
        
        ///Uploads an SQL statement to `website`+`writeFile`.
        ///
        ///This method will return control to your application immediately, deferring call back to `completion`.  `completion` will always be ran on the main thread
        ///- Parameter sqlStatement: an MSSQL object that contains a built SQL statement
        ///- Parameter completion: A block to be called when `website`+`writeFile` has returned either **Success** or **Failure**
        func uploadDataWithSQLStatement(_ sqlStatement: MSSQL, completion: @escaping (Bool) -> Void)
        {
            let url = URL(string: website)!.appendingPathComponent(writeFile)
            
            let postData = "Password=\(databaseUserPass)&Username=\(websiteUserName)&SQLQuery=\(sqlStatement.formattedStatement)".data(using: String.Encoding.ascii, allowLossyConversion: true)
            let postLength = String(postData!.count)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(postLength, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
            request.httpBody = postData
            
            MSDatabase.default.msNetworkActivityIndicatorManager.show()
            
            let uploadRequest = uploadSession.dataTask(with: request, completionHandler: { (returnData, response, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    debugLog("Error: \(error!)")
                    debugLog("Response: \(response!)")
                    MSDatabase.default.msNetworkActivityIndicatorManager.hide()
                    
                    guard response?.url?.absoluteString.hasPrefix(website) == true else { completion(false); return }
                    guard error == nil && returnData != nil else { completion(false); return }
                    guard let stringData = NSString(data: returnData!, encoding: String.Encoding.ascii.rawValue) else { completion(false); return }
                    debugLog("Return Data: \(stringData)")
                    guard stringData.contains("Success") else { completion(false); return }
                    
                    completion(true)
                })
            })
            
            uploadRequest.resume()
        }
        
        //MARK: - NSURLSessionDelegate
        
        func urlSession(_ session: Foundation.URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
        {
            let credential = URLCredential(user: websiteUserName, password: websiteUserPass, persistence: URLCredential.Persistence.forSession)
            
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
        }
    }
}
