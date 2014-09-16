//
//  Session.h
//  Theo
//
//  Created by Cory D. Wiles on 9/15/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

public struct Configuration {

  private let requestTimeout: Double  = 10
  private let resourceTimeout: Double = 20
  
  let sessionConfiguration: NSURLSessionConfiguration

  lazy private var cache: NSURLCache = {
    
    let memoryCacheLimit: Int = 10 * 1024 * 1024;
    let diskCapacity: Int = 50 * 1024 * 1024;
    
   /**
    * http://nsscreencast.com/episodes/91-afnetworking-2-0
    */
    
    let cache:NSURLCache = NSURLCache(memoryCapacity: memoryCacheLimit, diskCapacity: diskCapacity, diskPath: nil)
    
    return cache
  }()
  
  init() {
    
    let userPasswordString: String = "graph-1095:sqS7FrpojNHjJZcJBWtu"
    let userPasswordData: NSData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    let credentialEncoding: String = userPasswordData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
    let authString: String = "Basic \(credentialEncoding)"
    let additionalHeaders: [String:String] = ["Accept": "application/json", "Authorization": authString]
    
    sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    
    sessionConfiguration.requestCachePolicy         = NSURLRequestCachePolicy.ReturnCacheDataElseLoad
    sessionConfiguration.timeoutIntervalForRequest  = self.requestTimeout
    sessionConfiguration.timeoutIntervalForResource = self.resourceTimeout
    sessionConfiguration.HTTPAdditionalHeaders      = additionalHeaders
    sessionConfiguration.URLCache                   = self.cache
  }
}

class Session {
  
  private let sessionDescription = "com.graphstory.session"
  private struct Static {
    static var token : dispatch_once_t = 0
    static var instance : Session?
  }

  var session: NSURLSession
  var sessionDelegateQueue: NSOperationQueue = NSOperationQueue.mainQueue()
  
  struct SessionParams {
    static var delegate: NSURLSessionDelegate?
    static var queue: NSOperationQueue?
  }
  
  class var sharedInstance: Session {
    
    dispatch_once(&Static.token) {
      Static.instance = Session(sessionDelegate: SessionParams.delegate, queue: SessionParams.queue)
    }
    
    return Static.instance!
  }
  
  required init(sessionDelegate: NSURLSessionDelegate?, queue: NSOperationQueue?) {
    
    assert(sessionDelegate != nil, "Session delegate can't be nil")

    let configuration = Configuration()
    
    if let operationQueue = queue {
      self.sessionDelegateQueue = operationQueue
    }
    
    self.session = NSURLSession(configuration: configuration.sessionConfiguration, delegate: sessionDelegate, delegateQueue: self.sessionDelegateQueue)
    
    self.session.sessionDescription = sessionDescription
  }
  
  convenience init() {
    self.init(sessionDelegate: nil, queue: nil);
  }
}
