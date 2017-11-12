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

    public enum BoltClientError: Error {
        case missingNodeResponse
        case missingRelationshipResponse
        case queryUnsuccessful
        case fetchingRecordsUnsuccessful
        case unknownError
    }

    required public init(_ configuration: ClientConfigurationProtocol) throws {

        self.hostname = configuration.hostname
        self.port = configuration.port
        self.username = configuration.username
        self.password = configuration.password
        self.encrypted = configuration.encrypted

        let settings = ConnectionSettings(username: self.username, password: self.password, userAgent: "Theo 4.0.0")

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

    required public init(hostname: String = "localhost", port: Int = 7687, username: String = "neo4j", password: String = "neo4j", encrypted: Bool = true) throws {

        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
        self.encrypted = encrypted

        let settings = ConnectionSettings(username: username, password: password, userAgent: "Theo 4.0.0")

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

    public func connect(completionBlock: ((Result<Bool, AnyError>) -> ())? = nil) {

        do {
            try self.connection.connect { (connected) in
                completionBlock?(.success(connected))
            }
        } catch let error as Socket.Error {
            completionBlock?(.failure(AnyError(error)))
        } catch let error as Connection.ConnectionError {
            completionBlock?(.failure(AnyError(error)))
        } catch let error {
            print("Unknown error while connecting: \(error.localizedDescription)")
            completionBlock?(.failure(AnyError(error)))
        }
    }

    public func connectSync() -> Result<Bool, AnyError> {

        var theResult: Result<Bool, AnyError>! = nil
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        connect() { result in
            theResult = result
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return theResult
    }
    
    public func disconnect() {
        connection.disconnect()
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

    public func executeWithResult(request: Request, completionBlock: ((Result<(Bool, QueryResult), AnyError>) -> ())? = nil) {
        do {
            try connection.request(request) { (successResponse, response) in
                if successResponse == false {
                    completionBlock?(.failure(AnyError(BoltClientError.queryUnsuccessful)))
                } else {
                    let queryResponse = parseResponses(responses: response)
                    self.pullAll(partialQueryResult: queryResponse) { result in
                        switch result {
                        case let .failure(error):
                            completionBlock?(.failure(AnyError(error)))
                        case let .success((successResponse, queryResponse)):
                            if successResponse == false {
                                completionBlock?(.failure(AnyError(BoltClientError.queryUnsuccessful)))
                            } else {
                                completionBlock?(.success((successResponse, queryResponse)))
                            }
                        }
                    }
                }
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
        var rows = [[String:ResponseItem]]()
        var row = [String:ResponseItem]()

        for i in 0..<candidateList.count {
            if i > 0 && i % result.fields.count == 0 {
                rows.append(row)
                row = [String:ResponseItem]()
            }

            let field = result.fields.count > 0 ? result.fields[i % result.fields.count] : nil
            let candidate = candidateList[i]

            if let node = Node(data: candidate) {
                if let nodeId = node.id {
                    nodes[nodeId] = node
                }

                if let field = field {
                    row[field] = node
                }
            }

            else if let relationship = Relationship(data: candidate) {
                if let relationshipId = relationship.id {
                    relationships[relationshipId] = relationship
                }

                if let field = field {
                    row[field] = relationship
                }
            }

            else if let path = Path(data: candidate) {
                paths.append(path)

                if let field = field {
                    row[field] = path
                }
            }

            else if let record = candidate.uintValue() {
                if let field = field {
                    row[field] = record
                }
            }

            else if let record = candidate.intValue() {
                if let field = field {
                    row[field] = record
                }
            }

            else if let record = candidate as? ResponseItem {
                if let field = field {
                    row[field] = record
                }
            }

            else {
                let record = Record(entry: candidate)
                if let field = field {
                    row[field] = record
                }
            }
        }

        if row.count > 0 {
            rows.append(row)
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
        result.rows += rows

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

    internal func pullSynchronouslyAndIgnore() {
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

extension BoltClient { // Node functions

    //MARK: Create

    public func createAndReturnNode(node: Node, completionBlock: ((Result<Node, AnyError>) -> ())?) {
        let request = node.createRequest()
        performRequestWithReturnNode(request: request, completionBlock: completionBlock)
    }

    public func createAndReturnNodeSync(node: Node) -> Result<Node, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Node, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        createAndReturnNode(node: node) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func createNode(node: Node, completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = node.createRequest(withReturnStatement: false)
        performRequestWithNoReturnNode(request: request, completionBlock: completionBlock)
    }

    public func createNodeSync(node: Node) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        createNode(node: node) { result in
            theResult = result
            self.pullSynchronouslyAndIgnore()
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func createAndReturnNodes(nodes: [Node], completionBlock: ((Result<[Node], AnyError>) -> ())?) {
        let request = nodes.createRequest()
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, partialQueryResult)):
                if !isSuccess {
                    let error = AnyError(BoltClientError.queryUnsuccessful)
                    completionBlock?(.failure(error))
                } else {
                    self.pullAll(partialQueryResult: partialQueryResult) { response in
                        switch response {
                        case let .failure(error):
                            completionBlock?(.failure(error))
                        case let .success((isSuccess, queryResult)):
                            if !isSuccess {
                                let error = AnyError(BoltClientError.fetchingRecordsUnsuccessful)
                                completionBlock?(.failure(error))
                            } else {
                                let nodes: [Node] = queryResult.nodes.map { $0.value }
                                completionBlock?(.success(nodes))
                            }
                        }
                    }
                }
            }
        }
    }

    public func createAndReturnNodesSync(nodes: [Node]) -> Result<[Node], AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<[Node], AnyError> = .failure(AnyError(BoltClientError.unknownError))
        createAndReturnNodes(nodes: nodes) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func createNodes(nodes: [Node], completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = nodes.createRequest(withReturnStatement: false)
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, _)):
                completionBlock?(.success(isSuccess))
            }
        }
    }

    public func createNodesSync(nodes: [Node]) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        createNodes(nodes: nodes) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    //MARK: Update
    public func updateAndReturnNode(node: Node, completionBlock: ((Result<Node, AnyError>) -> ())?) {

        let request = node.updateRequest()
        performRequestWithReturnNode(request: request, completionBlock: completionBlock)
    }

    private func performRequestWithReturnNode(request: Request, completionBlock: ((Result<Node, AnyError>) -> ())?) {
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, partialQueryResult)):
                if !isSuccess {
                    let error = AnyError(BoltClientError.queryUnsuccessful)
                    completionBlock?(.failure(error))
                } else {
                    self.pullAll(partialQueryResult: partialQueryResult) { response in
                        switch response {
                        case let .failure(error):
                            completionBlock?(.failure(error))
                        case let .success((isSuccess, queryResult)):
                            if !isSuccess {
                                let error = AnyError(BoltClientError.fetchingRecordsUnsuccessful)
                                completionBlock?(.failure(error))
                            } else {
                                if let (_, node) = queryResult.nodes.first {
                                    completionBlock?(.success(node))
                                } else {
                                    let error = AnyError(BoltClientError.missingNodeResponse)
                                    completionBlock?(.failure(error))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public func updateAndReturnNodeSync(node: Node) -> Result<Node, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Node, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateAndReturnNode(node: node) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func updateNode(node: Node, completionBlock: ((Result<Bool, AnyError>) -> ())?) {

        let request = node.updateRequest()
        performRequestWithNoReturnNode(request: request, completionBlock: completionBlock)
    }

    public func performRequestWithNoReturnNode(request: Request, completionBlock: ((Result<Bool, AnyError>) -> ())?) {

        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, _)):
                completionBlock?(.success(isSuccess))
            }
        }
    }

    public func updateNodeSync(node: Node) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateNode(node: node) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func updateAndReturnNodes(nodes: [Node], completionBlock: ((Result<[Node], AnyError>) -> ())?) {
        let request = nodes.updateRequest()
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, partialQueryResult)):
                if !isSuccess {
                    let error = AnyError(BoltClientError.queryUnsuccessful)
                    completionBlock?(.failure(error))
                } else {
                    self.pullAll(partialQueryResult: partialQueryResult) { response in
                        switch response {
                        case let .failure(error):
                            completionBlock?(.failure(error))
                        case let .success((isSuccess, queryResult)):
                            if !isSuccess {
                                let error = AnyError(BoltClientError.fetchingRecordsUnsuccessful)
                                completionBlock?(.failure(error))
                            } else {
                                let nodes: [Node] = queryResult.nodes.map { $0.value }
                                completionBlock?(.success(nodes))
                            }
                        }
                    }
                }
            }
        }
    }

    public func updateAndReturnNodesSync(nodes: [Node]) -> Result<[Node], AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<[Node], AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateAndReturnNodes(nodes: nodes) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func updateNodes(nodes: [Node], completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = nodes.updateRequest(withReturnStatement: false)
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, _)):
                completionBlock?(.success(isSuccess))
            }
        }
    }

    public func updateNodesSync(nodes: [Node]) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateNodes(nodes: nodes) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    //MARK: Delete
    public func deleteNode(node: Node, completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = node.deleteRequest()
        performRequestWithNoReturnNode(request: request, completionBlock: completionBlock)
    }

    public func deleteNodeSync(node: Node) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        deleteNode(node: node) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult

    }

    public func deleteNodes(nodes: [Node], completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = nodes.deleteRequest()
        performRequestWithNoReturnNode(request: request, completionBlock: completionBlock)
    }

    public func deleteNodesSync(nodes: [Node]) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        deleteNodes(nodes: nodes) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

}

extension BoltClient { // Relationship functinos

    // Create

    public func relate(node: Node, to: Node, name: String, properties: [String:PackProtocol], completionBlock: ((Result<Relationship, AnyError>) -> ())?) {
        if let relationship = Relationship(fromNode: node, toNode: to, name: name, type: .from, properties: properties) {
            let request = relationship.createRequest()
            performRequestWithReturnRelationship(request: request, completionBlock: completionBlock)
        } else {
            print("Could not create relationship")
        }
    }

    public func relateSync(node: Node, to: Node, name: String, properties: [String:PackProtocol]) -> Result<Relationship, AnyError> {
        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Relationship, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        relate(node: node, to: to, name: name, properties: properties) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    //MARK: Update
    public func updateAndReturnRelationship(relationship: Relationship, completionBlock: ((Result<Relationship, AnyError>) -> ())?) {

        let request = relationship.updateRequest()
        performRequestWithReturnRelationship(request: request, completionBlock: completionBlock)
    }

    private func performRequestWithReturnRelationship(request: Request, completionBlock: ((Result<Relationship, AnyError>) -> ())?) {
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, partialQueryResult)):
                if !isSuccess {
                    let error = AnyError(BoltClientError.queryUnsuccessful)
                    completionBlock?(.failure(error))
                } else {
                    self.pullAll(partialQueryResult: partialQueryResult) { response in
                        switch response {
                        case let .failure(error):
                            completionBlock?(.failure(error))
                        case let .success((isSuccess, queryResult)):
                            if !isSuccess {
                                let error = AnyError(BoltClientError.fetchingRecordsUnsuccessful)
                                completionBlock?(.failure(error))
                            } else {
                                if let (_, relationship) = queryResult.relationships.first {
                                    completionBlock?(.success(relationship))
                                } else {
                                    let error = AnyError(BoltClientError.missingRelationshipResponse)
                                    completionBlock?(.failure(error))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public func updateAndReturnRelationshipSync(relationship: Relationship) -> Result<Relationship, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Relationship, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateAndReturnRelationship(relationship: relationship) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func updateRelationship(relationship: Relationship, completionBlock: ((Result<Bool, AnyError>) -> ())?) {

        let request = relationship.updateRequest()
        performRequestWithNoReturnRelationship(request: request, completionBlock: completionBlock)
    }

    public func performRequestWithNoReturnRelationship(request: Request, completionBlock: ((Result<Bool, AnyError>) -> ())?) {

        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, _)):
                completionBlock?(.success(isSuccess))
            }
        }
    }

    public func updateRelationshipSync(relationship: Relationship) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateRelationship(relationship: relationship) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    /*
    public func updateAndReturnRelationships(relationships: [Relationship], completionBlock: ((Result<[Relationship], AnyError>) -> ())?) {
        let request = relationships.updateRequest()
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, partialQueryResult)):
                if !isSuccess {
                    let error = AnyError(BoltClientError.queryUnsuccessful)
                    completionBlock?(.failure(error))
                } else {
                    self.pullAll(partialQueryResult: partialQueryResult) { response in
                        switch response {
                        case let .failure(error):
                            completionBlock?(.failure(error))
                        case let .success((isSuccess, queryResult)):
                            if !isSuccess {
                                let error = AnyError(BoltClientError.fetchingRecordsUnsuccessful)
                                completionBlock?(.failure(error))
                            } else {
                                let relationships: [Relationship] = queryResult.relationships.map { $0.value }
                                completionBlock?(.success(relationships))
                            }
                        }
                    }
                }
            }
        }
    }

    public func updateAndReturnRelationshipsSync(relationships: [Relationship]) -> Result<[Relationship], AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<[Relationship], AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateAndReturnRelationships(relationships: relationships) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }

    public func updateRelationships(relationships: [Relationship], completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = relationships.updateRequest(withReturnStatement: false)
        execute(request: request) { response in
            switch response {
            case let .failure(error):
                completionBlock?(.failure(error))
            case let .success((isSuccess, _)):
                completionBlock?(.success(isSuccess))
            }
        }
    }

    public func updateRelationshipsSync(relationships: [Relationship]) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        updateRelationships(relationships: relationships) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }*/

    //MARK: Delete
    public func deleteRelationship(relationship: Relationship, completionBlock: ((Result<Bool, AnyError>) -> ())?) {
        let request = relationship.deleteRequest()
        performRequestWithNoReturnRelationship(request: request, completionBlock: completionBlock)
    }

    public func deleteRelationshipSync(relationship: Relationship) -> Result<Bool, AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        deleteRelationship(relationship: relationship) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult

    }

    /*
    public func deleteRelationships(relationships: [Relationship], completionBlock: ((Result<[Bool], AnyError>) -> ())?) {
        let request = relationships.deleteRequest()
        performRequestWithNoReturnRelationship(request: request, completionBlock: completionBlock)
    }

    public func deleteRelationshipsSync(relationships: [Relationship]) -> Result<[Bool], AnyError> {

        let group = DispatchGroup()
        group.enter()

        var theResult: Result<Bool, AnyError> = .failure(AnyError(BoltClientError.unknownError))
        deleteRelationships(relationships: relationships) { result in
            theResult = result
            group.leave()
        }

        group.wait()
        return theResult
    }*/
}
