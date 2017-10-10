import Foundation

typealias RequestSuccessBlock = (_ data: Data?, _ response: URLResponse) -> Void
typealias RequestErrorBlock   = (_ error: NSError, _ response: URLResponse) -> Void

let TheoNetworkErrorDomain: String  = "com.theo.network.error"
let TheoAuthorizationHeader: String = "Authorization"

public struct AllowedHTTPMethods {

    static var GET: String    = "GET"
    static var PUT: String    = "PUT"
    static var POST: String   = "POST"
    static var DELETE: String = "DELETE"
}

class RestRequest {

    // MARK: Lazy properties

    lazy var httpSession: RestSession = {

        return RestSession.sharedInstance
    }()

    lazy var sessionConfiguration: URLSessionConfiguration = {
        return self.httpSession.configuration.sessionConfiguration
    }()

    lazy var sessionHTTPAdditionalHeaders: [AnyHashable: Any]? = {
        return self.sessionConfiguration.httpAdditionalHeaders
    }()

    let sessionURL: URL

    // MARK: Private properties

    fileprivate var userCredentials: (username: String, password: String)?

    // MARK: Constructors

    /// Designated initializer
    ///
    /// - parameter NSURL: url
    /// - parameter NSURLCredential?: credentials
    /// - parameter Array<String,String>?: additionalHeaders
    /// - returns: RestRequest
    required init(url: URL, credentials: (username: String, password: String)?, additionalHeaders:[String:String]?) {

        self.sessionURL  = url

        // If the additional headers aren't nil then we have to fake a mutable
        // copy of the sessionHTTPAdditionsalHeaders (they are immutable), add
        // out new ones and then set the values again

        if let additionalHeaders = additionalHeaders {

            var newHeaders: [String:String] = [:]

            if let sessionConfigurationHeaders = self.sessionHTTPAdditionalHeaders as? [String:String] {

                for (origininalHeader, originalValue) in sessionConfigurationHeaders {
                    newHeaders[origininalHeader] = originalValue
                }

                for (header, value) in additionalHeaders {
                    newHeaders[header] = value
                }
            }

            else {
                newHeaders = additionalHeaders
            }

            self.sessionConfiguration.httpAdditionalHeaders = newHeaders as [AnyHashable: Any]?

        }

        // More than likely your instance of Neo4j will require a username/pass.
        // If the credentials param is set the the storage and protection space
        // are set and passed to the configuration. This is set for all session
        // requests. This _might_ change in the future by utililizng the delegate
        // methods so that you can set whether or not requests should handle auth
        // at a session or task level.

        self.userCredentials = credentials
    }

    func urlRequest() -> URLRequest {
        var httpRequest = URLRequest(url: self.sessionURL)

        httpRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")

        if let userCreds = self.userCredentials {

            let userAuthString: String = self.basicAuthString(userCreds.username, password: userCreds.password)
            httpRequest.setValue(userAuthString, forHTTPHeaderField: TheoAuthorizationHeader)
        }

        return httpRequest
    }

    /// Convenience initializer
    ///
    /// The additionalHeaders property is set to nil
    ///
    /// - parameter NSURL: url
    /// - parameter NSURLCredential?: credentials
    /// - returns: RestRequest

    convenience init(url: URL, credentials: (username: String, password: String)?) {
        self.init(url: url, credentials: credentials, additionalHeaders: nil)
    }

    /// Convenience initializer
    ///
    /// The additionalHeaders and credentials properties are set to nil
    ///
    /// - parameter NSURL: url
    /// - returns: RestRequest

    convenience init() {
        self.init(url: URL(string: "this will fail")!, credentials: (username: String(), password: String()), additionalHeaders: nil)
    }

    // MARK: Public Methods

    /// Method makes a HTTP GET request
    ///
    /// - parameter RequestSuccessBlock: successBlock
    /// - parameter RequestErrorBlock: errorBlock
    /// - returns: Void
    func getResource(_ successBlock: RequestSuccessBlock? = nil, errorBlock: RequestErrorBlock? = nil) -> Void {

        let request: URLRequest = {

            var mutableRequest: URLRequest = urlRequest()
            mutableRequest.httpMethod = AllowedHTTPMethods.GET

            return mutableRequest
        }()



        let completionHandler : (Data?, URLResponse?, Error?) -> Void = {(data: Data?, response: URLResponse?, error: Error?) -> Void in

            guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
                if let errorCallBack = errorBlock {
                    let error = NSError(domain: "Invalid response", code: -1, userInfo: nil)
                    let url: URL = request.url ?? URL(string: "http://invalid.com/error")!
                    let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    errorCallBack(error, response)
                }
                return
            }

            var dataResp: Data? = data

            let statusCode = httpResponse.statusCode
            let containsStatusCode:Bool = RestRequest.acceptableStatusCodes().contains(statusCode)

            if !containsStatusCode {
                dataResp = nil
            }

            /// Process Success Block

            successBlock?(dataResp, httpResponse)

            /// Process Error Block

            if let errorCallBack = errorBlock {

                if error != nil { // How should this Error be NSError?

                    let nserror = NSError(domain: "Theo RestRequest", code: 1, userInfo: nil)
                    errorCallBack(nserror, httpResponse)
                    return
                }

                if !containsStatusCode {

                    let localizedErrorString: String = "There was an error processing the request"
                    let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response!.description]
                    let requestResponseError: NSError = {
                        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                    }()

                    errorCallBack(requestResponseError, httpResponse)
                }
            }

        }

        let task : URLSessionDataTask = self.httpSession.session.dataTask(with: request, completionHandler:completionHandler)

        task.resume()
    }

    /// Method makes a HTTP POST request
    ///
    /// - parameter RequestSuccessBlock: successBlock
    /// - parameter RequestErrorBlock: errorBlock
    /// - returns: Void
    func postResource(_ postData: Any, forUpdate: Bool, successBlock: RequestSuccessBlock? = nil, errorBlock: RequestErrorBlock? = nil) -> Void {


        let request: URLRequest = {

            var mutableRequest = urlRequest()
            mutableRequest.httpMethod = forUpdate == true ? AllowedHTTPMethods.PUT : AllowedHTTPMethods.POST

            mutableRequest.httpBody = Data()

            if let transformedJSONData: Data = try? JSONSerialization.data(withJSONObject: postData, options: []) {
                mutableRequest.httpBody = transformedJSONData
            }

            return mutableRequest
        }()

        let completionHandler = {(data: Data?, response: URLResponse?, error: Error?) -> Void in

            var dataResp: Data? = data
            guard let httpResponse = response as? HTTPURLResponse else {
                if let errorCallBack = errorBlock {
                    let error = NSError(domain: "Invalid response", code: -1, userInfo: nil)
                    let url: URL = request.url ?? URL(string: "http://invalid.com/error")!
                    let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                    errorCallBack(error, response)
                }
                return
            }

            let statusCode: Int = httpResponse.statusCode
            let containsStatusCode:Bool = RestRequest.acceptableStatusCodes().contains(statusCode)

            if !containsStatusCode {
                dataResp = nil
            }

            /// Process Success Block

            successBlock?(dataResp, httpResponse)

            /// Process Error Block

            if let errorCallBack = errorBlock {

                if error != nil { // How should this Error be NSError?

                    let nserror = NSError(domain: "Theo RestRequest", code: 1, userInfo: nil)
                    errorCallBack(nserror, httpResponse)
                    return
                }

                if !containsStatusCode {

                    let localizedErrorString: String = "There was an error processing the request"
                    let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response!.description]
                    let requestResponseError: NSError = {
                        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                    }()

                    errorCallBack(requestResponseError, httpResponse)
                }
            }
        }

        let task : URLSessionDataTask = self.httpSession.session.dataTask(with: request, completionHandler:completionHandler)

        task.resume()
    }

    /// Method makes a HTTP DELETE request
    ///
    /// - parameter RequestSuccessBlock: successBlock
    /// - parameter RequestErrorBlock: errorBlock
    /// - returns: Void
    func deleteResource(_ successBlock: RequestSuccessBlock? = nil, errorBlock: RequestErrorBlock? = nil) -> Void {

        let request: URLRequest = {

            var mutableRequest = urlRequest()
            mutableRequest.httpMethod = AllowedHTTPMethods.DELETE

            return mutableRequest
        }()

        let task : URLSessionDataTask = self.httpSession.session.dataTask(with: request, completionHandler: {(data: Data?, response: URLResponse?, error: Error?) -> Void in

            var dataResp: Data? = data
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            let statusCode: Int = httpResponse.statusCode
            let containsStatusCode:Bool = RestRequest.acceptableStatusCodes().contains(statusCode)

            if !containsStatusCode {
                dataResp = nil
            }

            /// Process Success Block

            successBlock?(dataResp, httpResponse)

            /// Process Error Block

            if let errorCallBack = errorBlock {

                if error != nil { // How should this Error be NSError?

                    let nserror = NSError(domain: "Theo RestRequest", code: 1, userInfo: nil)
                    errorCallBack(nserror, httpResponse)
                    return
                }

                if !containsStatusCode {

                    let localizedErrorString: String = "There was an error processing the request"
                    let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response!.description]
                    let requestResponseError: NSError = {
                        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                    }()

                    errorCallBack(requestResponseError, httpResponse)
                }
            }
        })

        task.resume()
    }

    /// Defines and range of acceptable HTTP response codes. 200 thru 300 inclusive
    ///
    /// - returns: NSIndexSet
    class func acceptableStatusCodes() -> IndexSet {

        let nsRange = NSMakeRange(200, 100)

        #if swift(>=4.0)
            let range = Range(nsRange) ?? 0..<0
            return IndexSet(integersIn: range)
        #elseif swift(>=3.0)
            return IndexSet(integersIn: nsRange.toRange() ?? 0..<0)
        #endif
    }

    // MARK: Private Methods

    /// Creates the base64 encoded string used for basic authorization
    ///
    /// - parameter String: username
    /// - parameter String: password
    /// - returns: String
    fileprivate func basicAuthString(_ username: String, password: String) -> String {

        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {

            let base64LoginString = loginData.base64EncodedString(options: [])
            let authString = "Basic \(base64LoginString)"

            return authString
        }

        return ""
    }
}
