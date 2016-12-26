//
//  MSDataUploader.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

///The data uploader class
///
///MSDataUploader connects to a `URL`, sends a `POST` request containing the SQL statement to run, downloads **Success** or **Failure**, and returns a Bool based upon that
public final class MSDataUploader: NSObject, URLSessionDelegate
{
    private var uploadSession : URLSession!
    
    override init()
    {
        super.init()
        
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpMaximumConnectionsPerHost = 10
        urlSessionConfiguration.httpAdditionalHeaders = ["Accept":"application/json"]
        
        uploadSession = URLSession(configuration: urlSessionConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
    
    /**
     Uploads an SQL statement to `website`+`writeFile`.
     
     This method will return control to your application immediately, deferring call back to `completion`.  `completion` will always be ran on the main thread
     
     
     - Parameter sqlStatement: an MSSQL object that contains a built SQL statement
     - Parameter completion: A block to be called when `website`+`writeFile` has returned either **Success** or **Failure**
     */
    public func upload(sqlStatement: MSSQL, completion: @escaping MSFrameworkUploadCompletion)
    {
        guard MSFrameworkManager.default.dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let url = URL(string: MSFrameworkManager.default.dataSource.website)!.appendingPathComponent(MSFrameworkManager.default.dataSource.writeFile)
        
        let postData = "Password=\(MSFrameworkManager.default.dataSource.databaseUserPass)&Username=\(MSFrameworkManager.default.dataSource.websiteUserName)&SQLQuery=\(sqlStatement.formattedStatement)".data(using: String.Encoding.ascii, allowLossyConversion: true)
        let postLength = String(postData!.count)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpBody = postData
        
        let uploadRequest = uploadSession.dataTask(with: request, completionHandler: { (returnData, response, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                
                debugLog("Error: \(error!)")
                debugLog("Response: \(response!)")
                
                guard response?.url?.absoluteString.hasPrefix(MSFrameworkManager.default.dataSource.website) == true else { completion(false); return }
                guard error == nil && returnData != nil else { completion(false); return }
                guard let stringData = NSString(data: returnData!, encoding: String.Encoding.ascii.rawValue) else { completion(false); return }
                debugLog("Return Data: \(stringData)")
                guard stringData.contains("Success") else { completion(false); return }
                
                completion(true)
            })
        })
        
        uploadRequest.resume()
    }
    
    //MARK: NSURLSessionDelegate
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        guard MSFrameworkManager.default.dataSource != nil else { fatalError("You must set a dataSource before querying any MSDatabase functionality.") }
        let credential = URLCredential(user: MSFrameworkManager.default.dataSource.websiteUserName, password: MSFrameworkManager.default.dataSource.websiteUserPass, persistence: URLCredential.Persistence.forSession)
        
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, credential)
    }
}
