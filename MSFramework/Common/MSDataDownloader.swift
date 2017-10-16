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
    private lazy var downloadSession : URLSession = {
        return URLSession(configuration: MSFrameworkManager.default.defaultSession, delegate: self, delegateQueue: nil)
    }()
    
    override init() { }
    
    ///Downloads JSON formatted data from `website`+`readFile`.
    ///
    ///This method will return control to your application immediately, deferring call back to `completion`. `completion` will always be ran on the main thread
    ///- Parameter sqlStatement: An MSSQL object that contains a built SQL statement
    ///- Parameter completion: A block to be called when all data has been downloaded
    public func download(sqlStatement: MSSQL, completion: MSFrameworkDownloadCompletion? = nil)
    {
        if MSFrameworkManager.debug { print(sqlStatement.formattedStatement) }
        guard let dataSource = MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let url = URL(string: dataSource.website)!.appendingPathComponent(dataSource.readFile)
        
        let postString = "Password=\(dataSource.databaseUserPass)&Username=\(dataSource.websiteUserName)&SQLQuery=\(sqlStatement.formattedStatement.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) ?? "")"
        if MSFrameworkManager.debug { print(postString) }
        let postData = postString.data(using: .utf8, allowLossyConversion: true)
        let postLength = String(postData!.count)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = postData
        
        downloadSession.dataTask(with: request, completionHandler: { returnData, response, error in
            DispatchQueue.main.async {
                if let error = error
                {
                    print(error)
                    completion?(nil, error)
                    return
                }
                if MSFrameworkManager.debug { print("Response: \(String(describing: response))") }
                
                guard response?.url?.absoluteString.hasPrefix(dataSource.website) == true else
                {
                    completion?(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidRedirect", code: 4, userInfo: ["website": response?.url?.absoluteString ?? "null"]))
                    return
                }
                guard let returnData = returnData else
                {
                    completion?(nil, NSError(domain: "com.Michael-Schloss.MSFramework.NoReturnData", code: 2, userInfo: nil))
                    return
                }
                guard let stringData = String(data: returnData, encoding: .utf8) else
                {
                    completion?(nil, NSError(domain: "com.Michael-Schloss.MSFramework.UnconvertableStringData", code: 3, userInfo: nil))
                    return
                }
                if MSFrameworkManager.debug { print("Return Data: \(stringData)") }
                guard stringData.contains("No Data") == false else
                {
                    completion?(nil, NSError(domain: "com.Michael-Schloss.MSFramework.NoData", code: 1, userInfo: nil))
                    return
                }
                MSFrameworkManager.default.msDataSizePrinter.printSize(returnData.count)
                do
                {
                    guard let downloadedData = try JSONSerialization.jsonObject(with: returnData, options: .allowFragments) as? NSDictionary, let returnArray = downloadedData["Data"] as? [Any] else
                    {
                        completion?(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil))
                        return
                    }
                    
                    if !dataSource.wantsCustomCDControl { MSFrameworkManager.default.msCoreDataStack.storeDataInCoreData(returnArray, sqlStatement: sqlStatement) }
                    completion?(returnArray, nil)
                }
                catch
                {
                    if MSFrameworkManager.debug
                    {
                        print("Raw Dump:\n\n" + stringData + "\n\n")
                        print(error)
                    }
                    completion?(nil, NSError(domain: "com.Michael-Schloss.MSFramework.InvalidJSONData" , code: 5, userInfo: nil));
                    return
                }
            }
        }).resume()
    }
    
    //MARK: - NSURLSessionDelegate
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        guard let dataSource =  MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        completionHandler(.useCredential, URLCredential(user: dataSource.websiteUserName, password: dataSource.websiteUserPass, persistence: .forSession))
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        guard let dataSource =  MSFrameworkManager.default.dataSource else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        completionHandler(.useCredential, URLCredential(user: dataSource.websiteUserName, password: dataSource.websiteUserPass, persistence: .forSession))
    }
}
