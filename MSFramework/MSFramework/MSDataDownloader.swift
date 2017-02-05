//
//  MSDataDownloader.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

///The data downloader class
///
///MSDataDownloader connects to a `URL`, sends a `POST` request, downloads JSON formatted data, then converts that data into an NSArray and returns it via a completionHandler
public final class MSDataDownloader: NSObject, URLSessionDelegate, URLSessionTaskDelegate
{
    private var downloadSession : URLSession!
    
    override init()
    {
        super.init()
        
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 10
        urlSessionConfiguration.httpAdditionalHeaders = ["Accept":"application/json"]
        
        downloadSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
    
    ///Downloads JSON formatted data from `website`+`readFile`.
    ///
    ///This method will return control to your application immediately, deferring call back to `completion`. `completion` will always be ran on the main thread
    ///- Parameter sqlStatement: An MSSQL object that contains a built SQL statement
    ///- Parameter completion: A block to be called when all data has been downloaded
    public func download(sqlStatement: MSSQL, completion: @escaping MSFrameworkDownloadCompletion)
    {
        debugLog(sqlStatement.formattedStatement)
        guard MSFrameworkManager.default.dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let url = URL(string: MSFrameworkManager.default.dataSource.website)!.appendingPathComponent(MSFrameworkManager.default.dataSource.readFile)
        
        let postData = "Password=\(MSFrameworkManager.default.dataSource.databaseUserPass)&Username=\(MSFrameworkManager.default.dataSource.websiteUserName)&SQLQuery=\(sqlStatement.formattedStatement)".data(using: String.Encoding.ascii, allowLossyConversion: true)
        let postLength = String(postData!.count)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = postData
        
        let downloadRequest = downloadSession.dataTask(with: request, completionHandler: { (returnData, response, error) in
            DispatchQueue.main.async(execute: { () -> Void in
                
                debugLog("Response: \(String(describing: response))")
                debugLog("Error: \(String(describing: error))")
                
                guard response?.url?.absoluteString.hasPrefix(MSFrameworkManager.default.dataSource.website) == true else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidRedirect", code: 4, userInfo: nil)); return }
                
                guard error == nil else { completion(nil, error); return }
                
                guard returnData != nil else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.NoReturnData", code: 2, userInfo: nil)); return }
                
                guard let stringData = String(data: returnData!, encoding: String.Encoding.ascii) else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.UnconvertableStringData", code: 3, userInfo: nil)); return }
                
                debugLog("Return Data: \(stringData)")
                
                guard stringData.contains("No Data") == false else { completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.NoData", code: 1, userInfo: nil)); return }
                
                MSFrameworkManager.default.msDataSizePrinter.printSize(returnData!.count)
                
                do
                {
                    let downloadedData = try JSONSerialization.jsonObject(with: returnData!, options: .allowFragments) as! NSDictionary
                    
                    guard let returnArray = downloadedData["Data"] as? [Any] else
                    {
                        completion(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil))
                        return
                    }
                    
                    if MSFrameworkManager.default.dataSource.wantsCustomCDControl == false
                    {
                        MSFrameworkManager.default.msCoreDataStack.storeDataInCoreData(returnArray, sqlStatement: sqlStatement)
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
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        guard MSFrameworkManager.default.dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let credential = URLCredential(user: MSFrameworkManager.default.dataSource.websiteUserName, password: MSFrameworkManager.default.dataSource.websiteUserPass, persistence: URLCredential.Persistence.forSession)
        
        completionHandler(.useCredential, credential)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        guard MSFrameworkManager.default.dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let credential = URLCredential(user: MSFrameworkManager.default.dataSource.websiteUserName, password: MSFrameworkManager.default.dataSource.websiteUserPass, persistence: URLCredential.Persistence.forSession)
        
        completionHandler(.useCredential, credential)
    }
}
