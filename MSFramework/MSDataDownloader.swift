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
    ///The data downloader class
    ///
    ///MSDataDownloader connects to a `URL`, sends a `POST` request, downloads JSON formatted data, then converts that data into an NSArray and returns it via a completionHandler
    class MSDataDownloader: NSObject, URLSessionDelegate, URLSessionTaskDelegate
    {
        private var downloadSession : Foundation.URLSession!
        
        override init()
        {
            super.init()
            
            let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.httpMaximumConnectionsPerHost = 10
            urlSessionConfiguration.httpAdditionalHeaders = ["Accept":"application/json"]
            
            downloadSession = Foundation.URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: OperationQueue())
        }
        
        ///Downloads JSON formatted data from `website`+`readFile`.
        ///
        ///This method will return control to your application immediately, deferring call back to `completion`. `completion` will always be ran on the main thread
        ///- Parameter sqlStatement: an MSSQL object that contains a built SQL statement
        ///- Parameter completion: A block to be called when all data has been downloaded.
        ///- Parameter returnArray: contains the data in iOS object format or will be `nil` is data wasn't downloaded successfully.
        ///- Parameter error: nil if `returnArray` has information, otherwise will contain the corresponding error
        func downloadDataWithSQLStatement(_ sqlStatement: MSSQL, completion: @escaping (_ returnArray : NSArray?, _ error: Error?) -> Void)
        {
            let url = URL(string: website)!.appendingPathComponent(readFile)
            
            let postData = "Password=\(databaseUserPass)&Username=\(websiteUserName)&SQLQuery=\(sqlStatement.formattedStatement)".data(using: String.Encoding.ascii, allowLossyConversion: true)
            let postLength = String(postData!.count)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(postLength, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
            request.httpBody = postData
            
            MSDatabase.default.msNetworkActivityIndicatorManager.show()
            
            let downloadRequest = downloadSession.dataTask(with: request, completionHandler: { (returnData, response, error) in
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    debugLog("Response: \(response)")
                    debugLog("Error: \(error)")
                    
                    MSDatabase.default.msNetworkActivityIndicatorManager.hide()
                    
                    guard response?.url?.absoluteString.hasPrefix(website) == true else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidRedirect", code: 4, userInfo: nil)); return }
                    
                    guard error == nil else { completion(nil, error); return }
                    
                    guard returnData != nil else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.NoReturnData", code: 2, userInfo: nil)); return }
                    
                    guard let stringData = String(data: returnData!, encoding: String.Encoding.ascii) else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.UnconvertableStringData", code: 3, userInfo: nil)); return }
                    
                    debugLog("Return Data: \(stringData)")
                    
                    guard stringData.contains("No Data") == false else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.NoData", code: 1, userInfo: nil)); return }
                    
                    MSDatabase.default.msDataSizePrinter.printSize(returnData!.count)
                    
                    do
                    {
                        let downloadedData = try JSONSerialization.jsonObject(with: returnData!, options: .allowFragments) as! NSDictionary
                        
                        guard let returnArray = downloadedData["Data"] as? NSArray else
                        {
                            completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil))
                            return
                        }
                        
                        completion(returnArray, nil)
                    }
                    catch
                    {
                        debugLog("Raw Dump:\n\n" + stringData + "\n\n")
                        debugLog(error)
                        completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil));
                        return
                    }
                })
            })
            
            downloadRequest.resume()
        }
        
        //MARK: - NSURLSessionDelegate
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
        {
            let credential = URLCredential(user: websiteUserName, password: websiteUserPass, persistence: URLCredential.Persistence.forSession)
            
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
        {
            let credential = URLCredential(user: websiteUserName, password: websiteUserPass, persistence: URLCredential.Persistence.forSession)
            
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
        }
    }
}
