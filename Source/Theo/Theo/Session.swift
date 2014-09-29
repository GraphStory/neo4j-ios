//
//  Session.swift
//  Cory D. Wiles
//
//  Created by Cory D. Wiles on 9/11/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation

public class Configuration {
  
    private let requestTimeout: Double  = 10
    private let resourceTimeout: Double = 20

    var sessionConfiguration: NSURLSessionConfiguration

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

        let additionalHeaders: [String:String] = ["Accept": "application/json", "Content-Type": "application/json; charset=UTF-8"]

        self.sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()

        self.sessionConfiguration.requestCachePolicy         = NSURLRequestCachePolicy.ReturnCacheDataElseLoad
        self.sessionConfiguration.timeoutIntervalForRequest  = self.requestTimeout
        self.sessionConfiguration.timeoutIntervalForResource = self.resourceTimeout
        self.sessionConfiguration.HTTPAdditionalHeaders      = additionalHeaders
        self.sessionConfiguration.URLCache                   = self.cache
    }
}

// TODO: Move all session request to utilize this delegate.
// Right now this will handle the authentication
private class TheoTaskSessionDelegate: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
    
    // For Session based challenges
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        println("session based challenge")
    }
    
    // For Session Task based challenges
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        println("session task based challenge")    
    }
}

class Session {
  
    private let sessionDescription = "com.graphstory.session"
    private struct Static {
        static var token : dispatch_once_t = 0
        static var instance : Session?
    }
    private let sessionDelegate: TheoTaskSessionDelegate = TheoTaskSessionDelegate()

    var session: NSURLSession
    var sessionDelegateQueue: NSOperationQueue = NSOperationQueue.mainQueue()
    var configuration: Configuration = Configuration()
  
    struct SessionParams {
        static var queue: NSOperationQueue?
    }
  
    class var sharedInstance: Session {
    
        dispatch_once(&Static.token) {
            Static.instance = Session(queue: SessionParams.queue)
        }

        return Static.instance!
    }
  
    required init(queue: NSOperationQueue?) {

        if let operationQueue = queue {
            self.sessionDelegateQueue = operationQueue
        }

        self.session = NSURLSession(configuration: configuration.sessionConfiguration, delegate: nil, delegateQueue: self.sessionDelegateQueue)

        self.session.sessionDescription = sessionDescription
    }
  
    convenience init() {
        self.init(queue: nil);
    }
}
