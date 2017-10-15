import Foundation
import PackStream
import Bolt
import Result
import Socket

#if os(Linux)
import Dispatch
#endif

public struct QueryWithParameters {
    let query: String
    let parameters: Dictionary<String,Any>
}

public class Transaction {

    public var succeed: Bool = true
    public var bookmark: String? = nil
    public var autocommit: Bool = true
    internal var commitBlock: (Bool) throws -> Void = { _ in }

    public init() {
    }

    public func markAsFailed() {
        succeed = false
    }
}

typealias BoltRequest = Bolt.Request

open class BoltClient {

    private let hostname: String
    private let port: Int
    private let username: String
    private let password: String
    private let encrypted: Bool
    private let connection: Connection

    private var currentTransaction: Transaction?

    required public init(hostname: String = "localhost", port: Int = 7687, username: String = "neo4j", password: String = "neo4j", encrypted: Bool = true) throws {

        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.encrypted = encrypted

        let settings = ConnectionSettings(username: username, password: password, userAgent: "Theo 3.1.2")

        let noConfig = SSLConfiguration(json: [:])
        let configuration = EncryptedSocket.defaultConfiguration(sslConfig: noConfig,
            allowHostToBeSelfSigned: true)

        let socket = try EncryptedSocket(
            hostname: hostname,
            port: port,
            configuration: configuration)

        self.connection = Connection(
            socket: socket,
            settings: settings)
    }

    public func connect(completionBlock: ((Result<Bool, Socket.Error>) -> ())? = nil) {

        do {
            try self.connection.connect { (connected) in
                completionBlock?(.success(connected))
            }
        } catch let error as Socket.Error {
            completionBlock?(.failure(error))
        } catch let error {
            print("Unhandled error while connecting: \(error.localizedDescription)")
        }
    }

    public func connectSync() -> Result<Bool, Socket.Error> {

        var theResult: Result<Bool, Socket.Error>! = nil
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        connect() { result in
            theResult = result
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return theResult
    }

    public func executeCypher(_ query: String, params: Dictionary<String,PackProtocol>? = nil, completionBlock: ((Result<Bool, Socket.Error>) -> ())? = nil) {

        let cypherRequest = BoltRequest.run(statement: query, parameters: Map(dictionary: params ?? [:]))

        do {
            try connection.request(cypherRequest) { (successResponse, response) in
                completionBlock?(.success(successResponse))

                //TODO: Handle response object
            }

        } catch let error as Socket.Error {
            completionBlock?(.failure(error))
        } catch let error {
            print("Unhandled error while executing cypher: \(error.localizedDescription)")
        }
    }

    public func executeCypherSync(_ query: String, params: Dictionary<String,PackProtocol>? = nil) -> (Result<[Response], Socket.Error>) {

        var theResult: Result<[Response], Socket.Error>! = nil
        let dispatchGroup = DispatchGroup()

        // Perform query
        dispatchGroup.enter()
        executeCypher(query, params: params) { result in
            switch result {
            case let .failure(error):
                print("Error: \(error)")
                theResult = .failure(error)
            case let .success(isSuccess):
                if isSuccess == false {
                    print("Query not successful")
                }
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        if theResult != nil {
            return theResult
        }

        // Stream and parse results
        dispatchGroup.enter()
        pullAll() { result in
            switch result {
            case let .failure(error):
                print("Error: \(error)")
                theResult = .failure(error)
            case let .success(isSuccess, results):
                if isSuccess == false {
                    print("Query not successful")
                } else {
                    theResult = .success(results)
                }
            }

            dispatchGroup.leave()
        }

        dispatchGroup.wait()
        return theResult
    }


    public func executeAsTransaction(bookmark: String? = nil, transactionBlock: @escaping (_ tx: Transaction) throws -> ()) throws {

        let transactionGroup = DispatchGroup()

        let transaction = Transaction()
        transaction.commitBlock = { succeed in
            if succeed {
                let commitRequest = BoltRequest.run(statement: "COMMIT", parameters: Map(dictionary: [:]))
                try self.connection.request(commitRequest) { (success, response) in
                    self.pullSynchronouslyAndIgnore()
                    if !success {
                        print("Error committing transaction: \(response)")
                    }
                    self.currentTransaction = nil
                    transactionGroup.leave()
                }
            } else {

                let rollbackRequest = BoltRequest.run(statement: "ROLLBACK", parameters: Map(dictionary: [:]))
                try self.connection.request(rollbackRequest) { (success, response) in
                    self.pullSynchronouslyAndIgnore()
                    if !success {
                        print("Error rolling back transaction: \(response)")
                    }
                    self.currentTransaction = nil
                    transactionGroup.leave()
                }
            }
        }

        currentTransaction = transaction

        let beginRequest = BoltRequest.run(statement: "BEGIN", parameters: Map(dictionary: [:]))

        transactionGroup.enter()

        try connection.request(beginRequest) { (success, response) in
            if success {

                pullSynchronouslyAndIgnore()

                try transactionBlock(transaction)
                if transaction.autocommit == true {
                    try transaction.commitBlock(transaction.succeed)
                    transaction.commitBlock = { _ in }
                }

            } else {
                print("Error beginning transaction: \(response)")
                transaction.commitBlock = { _ in }
                transactionGroup.leave()
            }
        }

        transactionGroup.wait()
    }

    private func pullSynchronouslyAndIgnore() {
        let dispatchGroup = DispatchGroup()
        let pullRequest = BoltRequest.pullAll()
        dispatchGroup.enter()
        do {
            try self.connection.request(pullRequest) { (success, response) in

                if let bookmark = self.getBookmark() {
                    currentTransaction?.bookmark = bookmark
                }
                dispatchGroup.leave()
            }
        } catch let error {
            print("Unhandled error while pulling to ignore all response data: \(error.localizedDescription)")
            dispatchGroup.leave()
        }
        dispatchGroup.wait()

    }

    public func pullAll(completionBlock: ((Result<(Bool, [Response]), Socket.Error>) -> ())? = nil) {
        let pullRequest = BoltRequest.pullAll()
        do {
            try self.connection.request(pullRequest) { (successResponse, response) in
            completionBlock?(.success((successResponse, response)))
        }
        } catch let error as Socket.Error {
            completionBlock?(.failure(error))
        } catch let error {
            print("Unhandled error while pulling all response data: \(error.localizedDescription)")
        }

    }

    public func getBookmark() -> String? {
        return connection.currentTransactionBookmark
    }

}
