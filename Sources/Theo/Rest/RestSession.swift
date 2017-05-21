import Foundation

#if os(Linux)
    import Dispatch
#endif

open class Configuration {

    fileprivate let requestTimeout: Double  = 10
    fileprivate let resourceTimeout: Double = 20

    var sessionConfiguration: URLSessionConfiguration

    lazy fileprivate var cache: URLCache = {

    let memoryCacheLimit: Int = 10 * 1024 * 1024
    let diskCapacity: Int = 50 * 1024 * 1024

   /**
    * http://nsscreencast.com/episodes/91-afnetworking-2-0
    */

    let cache:URLCache = URLCache(memoryCapacity: memoryCacheLimit, diskCapacity: diskCapacity, diskPath: nil)
        return cache
    }()

    init() {

        let additionalHeaders: [String:String] = ["Accept": "application/json", "Content-Type": "application/json; charset=UTF-8"]

        self.sessionConfiguration = URLSessionConfiguration.default

        self.sessionConfiguration.requestCachePolicy         = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        self.sessionConfiguration.timeoutIntervalForRequest  = self.requestTimeout
        self.sessionConfiguration.timeoutIntervalForResource = self.resourceTimeout
        self.sessionConfiguration.httpAdditionalHeaders      = additionalHeaders
//        self.sessionConfiguration.URLCache                   = self.cache
    }
}

// TODO: Move all session request to utilize this delegate.
// Right now these are NOT called because I'm setting the URLCredential on the
// session configuration
private class TheoTaskRestSessionDelegate: NSObject {

    // For RestSession based challenges
#if os(Linux)
    func URLSession(_ session: Foundation.URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("session based challenge")
    }

    // For Session Task based challenges
    func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("session task based challenge")
    }
#else
    @objc func URLSession(_ session: Foundation.URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("session based challenge")
    }

    // For Session Task based challenges
    @objc func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("session task based challenge")
    }

    #endif
}

class RestSession {


    // MARK: Private properties

    fileprivate let sessionDescription = "net.theo.restsession"
    fileprivate struct Static {
        static var token : Int = 0
        static var instance : RestSession?
    }
    fileprivate let sessionDelegate: TheoTaskRestSessionDelegate = TheoTaskRestSessionDelegate()

    // MARK: Public properties

    var session: URLSession
    var sessionDelegateQueue: OperationQueue
    var configuration: Configuration = Configuration()

    static var sharedInstance: RestSession = {
        let queue = OperationQueue()
        queue.name = "net.theo.restsession.queue"
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = DispatchQueue(label: TheoParsingQueueName, attributes: DispatchQueue.Attributes.concurrent)

        let session = RestSession(queue: queue)
        return session
    }()

    // MARK: Constructors

    /// Designated initializer
    ///
    /// The session delegate is set to nil and will use the "system" provided
    /// delegate
    ///
    /// - parameter NSOperationQueue?: queue
    /// - returns: RestSession
    required init(queue: OperationQueue?) {

        if let operationQueue = queue {
            self.sessionDelegateQueue = operationQueue
        } else {

            let operationQueue = RestSession.sharedInstance.sessionDelegateQueue
            self.sessionDelegateQueue = operationQueue
        }

        self.session = URLSession(configuration: configuration.sessionConfiguration, delegate: nil, delegateQueue: self.sessionDelegateQueue)

        self.session.sessionDescription = sessionDescription
    }

    /// Convenience initializer
    ///
    /// The operation queue param is set to nil which translates to using
    /// a new concurrent OperationQueue
    ///
    /// - returns: RestSession
    convenience init() {
        self.init(queue: nil)
    }
}
