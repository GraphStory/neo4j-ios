import Foundation
import PackStream
import Bolt

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

    public func connect(completionBlock: ((Bool) -> ())? = nil) throws {

        if let completionBlock = completionBlock {
            try self.connection.connect { (success) in
                completionBlock(success)
            }
        }

        else {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            try self.connection.connect { (success) in
                dispatchGroup.leave()
            }
            dispatchGroup.wait()
        }

    }


    private func pullSynchronouslyAndIgnore() throws {
        let dispatchGroup = DispatchGroup()
        let pullRequest = BoltRequest.pullAll()
        dispatchGroup.enter()
        try self.connection.request(pullRequest) { (success, response) in

            if let bookmark = self.getBookmark() {
                currentTransaction?.bookmark = bookmark
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()

    }

    public func pullAll(completionBlock: (Bool, [Response]) -> ()) throws {
        let pullRequest = BoltRequest.pullAll()
        try self.connection.request(pullRequest) { (success, response) in
            completionBlock(success, response)
        }

    }

    public func executeAsTransaction(bookmark: String? = nil, transactionBlock: @escaping (_ tx: Transaction) throws -> ()) throws {

        let transactionGroup = DispatchGroup()

        let transaction = Transaction()
        transaction.commitBlock = { succeed in
            if succeed {
                let commitRequest = BoltRequest.run(statement: "COMMIT", parameters: Map(dictionary: [:]))
                try self.connection.request(commitRequest) { (success, response) in
                    try self.pullSynchronouslyAndIgnore()
                    if !success {
                        print("Error committing transaction: \(response)")
                    }
                    self.currentTransaction = nil
                    transactionGroup.leave()
                }
            } else {

                let rollbackRequest = BoltRequest.run(statement: "ROLLBACK", parameters: Map(dictionary: [:]))
                try self.connection.request(rollbackRequest) { (success, response) in
                    try self.pullSynchronouslyAndIgnore()
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

                try pullSynchronouslyAndIgnore()

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

    public func executeTransaction(parameteredQueries: [QueryWithParameters], completionBlock: ClientProtocol.TheoCypherQueryCompletionBlock? = nil) -> Void {

    }

    public func executeCypher(_ query: String, params: Dictionary<String,PackProtocol>? = nil) throws -> Bool {

        var success = false

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let cypherRequest = BoltRequest.run(statement: query, parameters: Map(dictionary: params ?? [:]))

        try connection.request(cypherRequest) { (theSuccess, response) in
            success = theSuccess

            if theSuccess == true {
                let pullRequest = BoltRequest.pullAll()
                try self.connection.request(pullRequest) { (theSuccess, response) in

                    success = theSuccess
                    if let currentTransaction = self.currentTransaction,
                        theSuccess == false {
                        currentTransaction.markAsFailed()
                    }

                    dispatchGroup.leave()
                }

            } else {
                if let currentTransaction = self.currentTransaction {
                    currentTransaction.markAsFailed()
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        return success
    }

    public func executeCypher(_ query: String, params: Dictionary<String,PackProtocol>? = nil, completionBlock: ((Bool) throws -> ())) throws -> Void {

        let cypherRequest = BoltRequest.run(statement: query, parameters: Map(dictionary: params ?? [:]))

        try connection.request(cypherRequest) { (success, response) in
            try completionBlock(success)
        }
    }

    public func getBookmark() -> String? {
        return connection.currentTransactionBookmark
    }

}
