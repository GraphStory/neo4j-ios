//
//  Request.swift
//  Cory D. Wiles
//
//  Created by Cory D. Wiles on 9/11/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

typealias RequestSuccessBlock = (data: NSData?, response: NSURLResponse) -> Void
typealias RequestErrorBlock   = (error: NSError, response: NSURLResponse) -> Void

let TheoNetworkErrorDomain: String  = "com.theo.network.error"
let TheoAuthorizationHeader: String = "Authorization"

public struct AllowedHTTPMethods {
  
    static var GET: String    = "GET"
    static var PUT: String    = "PUT"
    static var POST: String   = "POST"
    static var DELETE: String = "DELETE"
}

class Request {
  
    // MARK: Lazy properties

    lazy var httpSession: Session = {

        Session.SessionParams.queue = NSOperationQueue.mainQueue()

        return Session.sharedInstance;
    }()
  
    lazy var sessionConfiguration: NSURLSessionConfiguration = {
        return self.httpSession.configuration.sessionConfiguration
    }()
  
    lazy var sessionHTTPAdditionalHeaders: [NSObject:AnyObject]? = {
        return self.sessionConfiguration.HTTPAdditionalHeaders
    }()
  
    let sessionURL: NSURL
    
    // MARK: Private properties

    private var httpRequest: NSURLRequest
    
    private var userCredentials: (username: String, password: String)?

    // MARK: Constructors
    
    /// Designated initializer
    ///
    /// - parameter NSURL: url
    /// - parameter NSURLCredential?: credentials
    /// - parameter Array<String,String>?: additionalHeaders
    /// - returns: Request
    required init(url: NSURL, credentials: (username: String, password: String)?, additionalHeaders:[String:String]?) {

        self.sessionURL  = url
        self.httpRequest = NSURLRequest(URL: self.sessionURL)
    
        // If the additional headers aren't nil then we have to fake a mutable 
        // copy of the sessionHTTPAdditionsalHeaders (they are immutable), add 
        // out new ones and then set the values again

        if additionalHeaders != nil {

            var newHeaders: [String:String] = [:]

            if let sessionConfigurationHeaders = self.sessionHTTPAdditionalHeaders as? [String:String] {
      
                for (origininalHeader, originalValue) in sessionConfigurationHeaders {
                    newHeaders[origininalHeader] = originalValue
                }
        
                for (header, value) in additionalHeaders! {
                    newHeaders[header] = value
                }
            }
      
            self.sessionConfiguration.HTTPAdditionalHeaders = newHeaders as [NSObject:AnyObject]?
      
        } else {
      
           // self.sessionURL = url
        }
        
        // More than likely your instance of Neo4j will require a username/pass.
        // If the credentials param is set the the storage and protection space 
        // are set and passed to the configuration. This is set for all session
        // requests. This _might_ change in the future by utililizng the delegate
        // methods so that you can set whether or not requests should handle auth
        // at a session or task level.

        self.userCredentials = credentials
    }
  
    /// Convenience initializer
    ///
    /// The additionalHeaders property is set to nil
    ///
    /// - parameter NSURL: url
    /// - parameter NSURLCredential?: credentials
    /// - returns: Request

    convenience init(url: NSURL, credentials: (username: String, password: String)?) {
        self.init(url: url, credentials: credentials, additionalHeaders: nil)
    }
    
    /// Convenience initializer
    ///
    /// The additionalHeaders and credentials properties are set to nil
    ///
    /// - parameter NSURL: url
    /// - returns: Request
    
    convenience init() {
        self.init(url: NSURL(), credentials: (username: String(), password: String()), additionalHeaders: nil)
    }
  
    // MARK: Public Methods

    /// Method makes a HTTP GET request
    ///
    /// - parameter RequestSuccessBlock: successBlock
    /// - parameter RequestErrorBlock: errorBlock
    /// - returns: Void
    func getResource(successBlock: RequestSuccessBlock?, errorBlock: RequestErrorBlock?) -> Void {

        let request: NSURLRequest = {
      
            let mutableRequest: NSMutableURLRequest = self.httpRequest.mutableCopy() as! NSMutableURLRequest
      
            mutableRequest.HTTPMethod = AllowedHTTPMethods.GET
            
            if let userCreds = self.userCredentials {
                
                let userAuthString: String = self.basicAuthString(userCreds.username, password: userCreds.password)
                
                mutableRequest.setValue(userAuthString, forHTTPHeaderField: TheoAuthorizationHeader)
            }
      
            return mutableRequest.copy() as! NSURLRequest
        }()

        let task : NSURLSessionDataTask = self.httpSession.session.dataTaskWithRequest(request, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
      
            var dataResp: NSData? = data
            let httpResponse: NSHTTPURLResponse = response as! NSHTTPURLResponse
            let statusCode: Int = httpResponse.statusCode
            let containsStatusCode:Bool = Request.acceptableStatusCodes().containsIndex(statusCode)

            if (!containsStatusCode) {
                dataResp = nil
            }
      
            if (successBlock != nil) {
                successBlock!(data: dataResp, response: httpResponse)
            }
      
            if (errorBlock != nil) {
        
                if (error != nil) {
                    errorBlock!(error: error!, response: httpResponse)
                }
        
                if (!containsStatusCode) {

                    let localizedErrorString: String = "There was an error processing the request"
                    let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response!.description]
                    let requestResponseError: NSError = {
                        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                    }()
          
                    errorBlock!(error: requestResponseError, response: httpResponse)
                }
            }
        })
    
        task.resume()
    }

    /// Method makes a HTTP POST request
    ///
    /// - parameter RequestSuccessBlock: successBlock
    /// - parameter RequestErrorBlock: errorBlock
    /// - returns: Void
    func postResource(postData: AnyObject, forUpdate: Bool, successBlock: RequestSuccessBlock?, errorBlock: RequestErrorBlock?) -> Void {
        
        let request: NSURLRequest = {

            let mutableRequest: NSMutableURLRequest = self.httpRequest.mutableCopy() as! NSMutableURLRequest
            let transformedJSONData: NSData = try! NSJSONSerialization.dataWithJSONObject(postData, options: [])
            
            mutableRequest.HTTPMethod = forUpdate == true ? AllowedHTTPMethods.PUT : AllowedHTTPMethods.POST
            mutableRequest.HTTPBody   = transformedJSONData
            
            if let userCreds = self.userCredentials {
                
                let userAuthString: String = self.basicAuthString(userCreds.username, password: userCreds.password)
                
                mutableRequest.setValue(userAuthString, forHTTPHeaderField: TheoAuthorizationHeader)
            }
            
            return mutableRequest.copy() as! NSURLRequest
        }()
        
        let task : NSURLSessionDataTask = self.httpSession.session.dataTaskWithRequest(request, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            var dataResp: NSData? = data
            let httpResponse: NSHTTPURLResponse = response as! NSHTTPURLResponse
            let statusCode: Int = httpResponse.statusCode
            let containsStatusCode:Bool = Request.acceptableStatusCodes().containsIndex(statusCode)
            
            if (!containsStatusCode) {
                dataResp = nil
            }
            
            if (successBlock != nil) {
                successBlock!(data: dataResp, response: httpResponse)
            }
            
            if (errorBlock != nil) {
                
                if (error != nil) {
                    errorBlock!(error: error!, response: httpResponse)
                }
                
                if (!containsStatusCode) {
                    
                    let localizedErrorString: String = "There was an error processing the request"
                    let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response!.description]
                    let requestResponseError: NSError = {
                        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                    }()
                    
                    errorBlock!(error: requestResponseError, response: httpResponse)
                }
            }
        })
        
        task.resume()
    }
    
    /// Method makes a HTTP DELETE request
    ///
    /// - parameter RequestSuccessBlock: successBlock
    /// - parameter RequestErrorBlock: errorBlock
    /// - returns: Void
    func deleteResource(successBlock: RequestSuccessBlock?, errorBlock: RequestErrorBlock?) -> Void {
    
        let request: NSURLRequest = {
            
            let mutableRequest: NSMutableURLRequest = self.httpRequest.mutableCopy() as! NSMutableURLRequest
            
            mutableRequest.HTTPMethod = AllowedHTTPMethods.DELETE
        
            if let userCreds = self.userCredentials {
                
                let userAuthString: String = self.basicAuthString(userCreds.username, password: userCreds.password)
                
                mutableRequest.setValue(userAuthString, forHTTPHeaderField: TheoAuthorizationHeader)
            }
            
            return mutableRequest.copy() as! NSURLRequest
        }()
        
        self.httpRequest = request
        
        let task : NSURLSessionDataTask = self.httpSession.session.dataTaskWithRequest(self.httpRequest, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            var dataResp: NSData? = data
            let httpResponse: NSHTTPURLResponse = response as! NSHTTPURLResponse
            let statusCode: Int = httpResponse.statusCode
            let containsStatusCode:Bool = Request.acceptableStatusCodes().containsIndex(statusCode)
            
            if (!containsStatusCode) {
                dataResp = nil
            }
            
            if (successBlock != nil) {
                successBlock!(data: dataResp, response: httpResponse)
            }
            
            if (errorBlock != nil) {
                
                if (error != nil) {
                    errorBlock!(error: error!, response: httpResponse)
                }
                
                if (!containsStatusCode) {
                    
                    let localizedErrorString: String = "There was an error processing the request"
                    let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response!.description]
                    let requestResponseError: NSError = {
                        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                    }()
                    
                    errorBlock!(error: requestResponseError, response: httpResponse)
                }
            }
        })
        
        task.resume()
    }
  
    /// Defines and range of acceptable HTTP response codes. 200 thru 300 inclusive
    ///
    /// - returns: NSIndexSet
    class func acceptableStatusCodes() -> NSIndexSet {
    
        let nsRange = NSMakeRange(200, 100)
    
        return NSIndexSet(indexesInRange: nsRange)
    }
    
    // MARK: Private Methods
    
    /// Creates the base64 encoded string used for basic authorization
    ///
    /// - parameter String: username
    /// - parameter String: password
    /// - returns: String
    private func basicAuthString(username: String, password: String) -> String {
    
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions([])
        let authString = "Basic \(base64LoginString)"

        return authString
    }
}
