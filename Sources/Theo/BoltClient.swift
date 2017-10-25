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

    public func execute(request: Request, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())? = nil) {
        do {
            try connection.request(request) { (successResponse, response) in
                let queryResponse = parseResponses(responses: response)
                completionBlock?(.success((successResponse, queryResponse)))
            }
            
        } catch let error as Socket.Error {
            completionBlock?(.failure(AnyError(error)))
        } catch let error as Response.ResponseError {
            completionBlock?(.failure(AnyError(error)))
        } catch let error {
            print("Unhandled error while executing cypher: \(error.localizedDescription)")
        }
    }
    
    public func executeCypher(_ query: String, params: Dictionary<String,PackProtocol>? = nil, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())? = nil) {

        let cypherRequest = BoltRequest.run(statement: query, parameters: Map(dictionary: params ?? [:]))

        execute(request: cypherRequest, completionBlock: completionBlock)

    }

    public func executeCypherSync(_ query: String, params: Dictionary<String,PackProtocol>? = nil) -> (Result<QueryResult, AnyError>) {

        var theResult: Result<QueryResult, AnyError>! = nil
        let dispatchGroup = DispatchGroup()

        // Perform query
        dispatchGroup.enter()
        var partialResult = QueryResult()
        executeCypher(query, params: params) { result in
            switch result {
            case let .failure(error):
                print("Error: \(error)")
                theResult = .failure(error)
            case let .success((isSuccess, _partialResult)):
                if isSuccess == false {
                    print("Query not successful")
                } else {
                    partialResult = _partialResult
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
        pullAll(partialQueryResult: partialResult) { result in
            switch result {
            case let .failure(error):
                print("Error: \(error)")
                theResult = .failure(error)
            case let .success(isSuccess, parsedResponses):
                if isSuccess == false {
                    print("Query not successful")
                } else {
                    theResult = .success(parsedResponses)
                }
            }

            dispatchGroup.leave()
        }

        dispatchGroup.wait()
        return theResult
    }



    private func parseResponses(responses: [Response], result: QueryResult = QueryResult()) -> QueryResult {
        let fields = (responses.flatMap { $0.items } .flatMap { ($0 as? Map)?.dictionary["fields"] }.first as? List)?.items.flatMap { $0 as? String }
        if let fields = fields {
            result.fields = fields
        }

        let stats = responses.flatMap { $0.items.flatMap { $0 as? Map }.flatMap { QueryStats(data: $0) } }.first
        if let stats = stats {
            result.stats = stats
        }

        if let resultAvailableAfter = (responses.flatMap { $0.items } .flatMap { ($0 as? Map)?.dictionary["result_available_after"] }.first?.uintValue()) {
            result.stats.resultAvailableAfter = resultAvailableAfter
        }

        if let resultConsumedAfter = (responses.flatMap { $0.items } .flatMap { $0 as? Map }.first?.dictionary["result_consumed_after"]?.uintValue()) {
            result.stats.resultConsumedAfter = resultConsumedAfter
        }

        if let type = (responses.flatMap { $0.items } .flatMap { $0 as? Map }.first?.dictionary["type"] as? String) {
            result.stats.type = type
        }



        let candidateList = responses.flatMap { $0.items.flatMap { ($0 as? List)?.items } }.reduce( [], +)
        var nodes = [UInt64:Node]()
        var relationships = [UInt64:Relationship]()
        var paths = [Path]()
        var responseItemDicts = [[String:ResponseItem]]()
        var responseItemDict = [String:ResponseItem]()

        for i in 0..<candidateList.count {
            if i > 0 && i % result.fields.count == 0 {
                responseItemDicts.append(responseItemDict)
                responseItemDict = [String:ResponseItem]()
            }

            let field = result.fields.count > 0 ? result.fields[i % result.fields.count] : nil
            let candidate = candidateList[i]

            if let node = Node(data: candidate) {
                if let nodeId = node.id {
                    nodes[nodeId] = node
                }

                if let field = field {
                    responseItemDict[field] = node
                }
            }

            else if let relationship = Relationship(data: candidate) {
                if let relationshipId = relationship.id {
                    relationships[relationshipId] = relationship
                }

                if let field = field {
                    responseItemDict[field] = relationship
                }
            }

            else if let path = Path(data: candidate) {
                paths.append(path)

                if let field = field {
                    responseItemDict[field] = path
                }
            }

            else if let record = candidate.uintValue() {
                if let field = field {
                    responseItemDict[field] = record
                }
            }

            else if let record = candidate.intValue() {
                if let field = field {
                    responseItemDict[field] = record
                }
            }

            else if let record = candidate as? ResponseItem {
                if let field = field {
                    responseItemDict[field] = record
                }
            }

            else {
                let record = Record(entry: candidate)
                if let field = field {
                    responseItemDict[field] = record
                }
            }
        }

        if responseItemDict.count > 0 {
            responseItemDicts.append(responseItemDict)
        }

        result.nodes.merge(nodes) { (n, _) -> Node in return n }

        let mapper: (UInt64, Relationship) -> (UInt64, Relationship) = { (key: UInt64, rel: Relationship) in
            rel.fromNode = nodes[rel.fromNodeId]
            rel.toNode = nodes[rel.toNodeId]
            return (key, rel)
        }

        let updatedRelationships = Dictionary(uniqueKeysWithValues: relationships.map(mapper))
        result.relationships.merge(updatedRelationships) { (r, _) -> Relationship in return r }

        result.paths += paths
        result.responseItemDicts += responseItemDicts

        return result

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

    public func pullAll(partialQueryResult: QueryResult = QueryResult(), completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())? = nil) {
        let pullRequest = BoltRequest.pullAll()
        do {
            try self.connection.request(pullRequest) { (successResponse, responses) in
                
                let result = parseResponses(responses: responses, result: partialQueryResult)
                completionBlock?(.success((successResponse, result)))
            }
        } catch let error as Socket.Error {
            completionBlock?(.failure(AnyError(error)))
        } catch let error {
            completionBlock?(.failure(AnyError(error)))
            print("Unexpected error while pulling all response data: \(error.localizedDescription)")
        }
        
    }

    public func getBookmark() -> String? {
        return connection.currentTransactionBookmark
    }

}
