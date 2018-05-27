import Foundation
import XCTest
import PackStream
import Socket
import Result

@testable import Theo

#if os(Linux)
    import Dispatch
#endif

let TheoTimeoutInterval: TimeInterval = 10

class ConfigLoader: NSObject {

    class func loadBoltConfig() -> BoltConfig {

        let testPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent().path

        let filePath = "\(testPath)/TheoBoltConfig.json"

        return BoltConfig(pathToFile: filePath)
    }

}

class Theo_000_BoltClientTests: XCTestCase {

    let configuration: BoltConfig = ConfigLoader.loadBoltConfig()
    static var runCount: Int = 0

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        Theo_000_BoltClientTests.runCount = Theo_000_BoltClientTests.runCount + 1
    }

    private func performConnectSync(client: BoltClient, completionBlock: ((Bool) -> ())? = nil) {

        let result = client.connectSync()
        switch result {
        case let .failure(error):
            if let theError = error.error as? Socket.Error,
                theError.errorCode == -9806 { // retry aborted connection
                client.disconnect()
                performConnectSync(client: client, completionBlock: completionBlock)
            } else {
                XCTFail("Failed connecting with error: \(error)")
                completionBlock?(false)
            }
        case let .success(isSuccess):
            XCTAssertTrue(isSuccess)
            completionBlock?(true)
        }
    }


    private func performConnect(client: BoltClient, completionBlock: ((Bool) -> ())? = nil) {
        client.connect() { connectionResult in
            switch connectionResult {
            case let .failure(error):
                if let theError = error.error as? Socket.Error,
                   theError.errorCode == -9806 { // retry aborted connection
                    self.performConnect(client: client) { result in
                        completionBlock?(result)
                    }
                } else {
                    XCTFail()
                    completionBlock?(false)
                }
            case let .success(isConnected):
                if !isConnected {
                    print("Error, could not connect!")
                }
                completionBlock?(isConnected)
            }
        }
    }

    internal func makeClient() throws -> BoltClient {
        let client: BoltClient
        
        if Theo_000_BoltClientTests.runCount % 3 == 0 {
            client = try BoltClient(hostname: configuration.hostname,
                                    port: configuration.port,
                                    username: configuration.username,
                                    password: configuration.password,
                                    encrypted: configuration.encrypted)
        } else if Theo_000_BoltClientTests.runCount % 3 == 1 {
            class CustomConfig: ClientConfigurationProtocol {
                let hostname: String
                let username: String
                let password: String
                let port: Int
                let encrypted: Bool
                
                init(configuration: BoltConfig) {
                    hostname = configuration.hostname
                    password = configuration.password
                    username = configuration.username
                    port = configuration.port
                    encrypted = configuration.encrypted
                }
            }
            client = try BoltClient(CustomConfig(configuration: configuration))
        } else {
            let testPath = URL(fileURLWithPath: #file)
                .deletingLastPathComponent().path
            let filePath = "\(testPath)/TheoBoltConfig.json"
            let data = try Data(contentsOf: URL.init(fileURLWithPath: filePath))

            let json = try JSONSerialization.jsonObject(with: data) as! [String:Any]
            let jsonConfig = JSONClientConfiguration(json: json)
            client = try BoltClient(jsonConfig)
        }


        if Theo_000_BoltClientTests.runCount % 2 == 0 {
            let group = DispatchGroup()
            group.enter()
            performConnect(client: client) { connectionSuccessful in
                XCTAssertTrue(connectionSuccessful)
                group.leave()
            }
            group.wait()
        } else {
            performConnectSync(client: client) { connectionSuccessful in
                XCTAssertTrue(connectionSuccessful)
            }
        }

        return client
    }

    func testNodeResult() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testNodeResult")

        XCTAssertTrue(client.executeCypherSync("CREATE (n:TheoTestNodeWithALongLabel { foo: \"bar\", baz: 3}) RETURN n").isSuccess)
        exp.fulfill()

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testRelationshipResult() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testNodeResult")

        let query = """
                    CREATE (b:Candidate {name:'Bala'})
                    CREATE (e:Employer {name:'Yahoo'})
                    CREATE (b)-[r:WORKED_IN]->(e)
                    RETURN b,r,e
                    """

        XCTAssertTrue(client.executeCypherSync(query).isSuccess)
        exp.fulfill()

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testIntroToCypher() throws {

        let client = try makeClient()
        let exp = self.expectation(description: "testNodeResult")
        var queries = [String]()

        queries.append(
                   """
                     MATCH (n)
                     DETACH DELETE n
                   """)

        queries.append(
                   """
                      CREATE (you:Person {name:"You"})
                      RETURN you
                   """)

        queries.append(
                   """
                      MATCH  (you:Person {name:"You"})
                      CREATE (you)-[like:LIKE]->(neo:Database {name:"Neo4j" })
                      RETURN you,like,neo
                   """)

        queries.append(
                   """
                      MATCH (you:Person {name:"You"})
                      FOREACH (name in ["Johan","Rajesh","Anna","Julia","Andrew"] |
                      CREATE (you)-[:FRIEND]->(:Person {name:name}))
                   """)

        queries.append(
                   """
                      MATCH (you {name:"You"})-[:FRIEND]->(yourFriends)
                      RETURN you, yourFriends
                   """)

        queries.append(
                   """
                      MATCH (neo:Database {name:"Neo4j"})
                      MATCH (anna:Person {name:"Anna"})
                      CREATE (anna)-[:FRIEND]->(:Person:Expert {name:"Amanda"})-[:WORKED_WITH]->(neo)
                   """)

        queries.append(
                   """
                      MATCH (you {name:"You"})
                      MATCH (expert)-[w:WORKED_WITH]->(db:Database {name:"Neo4j"})
                      MATCH path = shortestPath( (you)-[:FRIEND*..5]-(expert) )
                      RETURN DISTINCT db,w,expert,path
                   """)

        for query in queries {
            XCTAssertTrue(client.executeCypherSync(query).isSuccess)

        }
        exp.fulfill()

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testSetOfQueries() throws {

        let client = try makeClient()
        let exp = self.expectation(description: "testSetOfQueries")
        var queries = [String]()

        queries.append(
            """
              CREATE (you:Person {name:"You", weight: 80})
              RETURN you.name, sum(you.weight) as singleSum
            """)

        queries.append(
            """
              MATCH (you:Person {name:"You"})
              RETURN you.name, sum(you.weight) as allSum, you
            """)


        for query in queries {
            XCTAssertTrue(client.executeCypherSync(query).isSuccess)

        }
        exp.fulfill()

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }


    func testSucceedingTransactionSync() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testSucceedingTransaction")

        do {
            try client.executeAsTransaction() { (tx) in
                XCTAssertTrue(client.executeCypherSync("CREATE (n:TheoTestNode { foo: \"bar\"})").isSuccess)
                XCTAssertTrue(client.executeCypherSync("MATCH (n:TheoTestNode { foo: \"bar\"}) RETURN n").isSuccess)
                XCTAssertTrue(client.executeCypherSync("MATCH (n:TheoTestNode { foo: \"bar\"}) DETACH DELETE n").isSuccess)
                exp.fulfill()
            }
        } catch let error {
            print("Failed transaction with error \(error)")
            XCTFail()
        }

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testFailingTransactionSync() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testFailingTransaction")

        try client.executeAsTransaction() { (tx) in
            XCTAssertTrue(client.executeCypherSync("CREATE (n:TheoTestNode { foo: \"bar\"})").isSuccess)
            XCTAssertTrue(client.executeCypherSync("MATCH (n:TheoTestNode { foo: \"bar\"}) RETURN n").isSuccess)
            XCTAssertFalse(client.executeCypherSync("MAXXXTCH (n:TheoTestNode { foo: \"bar\"}) DETACH DELETE n").isSuccess)
            tx.markAsFailed()

            XCTAssertFalse(tx.succeed)
            exp.fulfill()
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testCancellingTransaction() throws {
        measure {
            do {
                let client = try self.makeClient()
                let exp = self.expectation(description: "testCancellingTransaction")
                
                try client.executeAsTransaction() { (tx) in
                    tx.markAsFailed()
                    exp.fulfill()
                }
                
                self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
                    XCTAssertNil(error)
                })
            } catch { XCTFail() }
        }
    }

    func testTransactionResultsInBookmark() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testTransactionResultsInBookmark")

        try client.executeAsTransaction() { (tx) in
            client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})") { result in
                switch result {
                case let .failure(error):
                    print("Error in cypher: \(error)")
                case let .success((success, partialQueryResult)):
                    if success {
                        client.pullAll(partialQueryResult: partialQueryResult) { result in
                            switch result {
                            case let .failure(error):
                                print("Error in cypher: \(error)")
                            case let .success((success, queryResult)):
                                XCTAssertTrue(success)
                                XCTAssertEqual(1, queryResult.stats.propertiesSetCount)
                                XCTAssertEqual(1, queryResult.stats.labelsAddedCount)
                                XCTAssertEqual(1, queryResult.stats.nodesCreatedCount)
                                XCTAssertEqual("w", queryResult.stats.type)
                                XCTAssertEqual(0, queryResult.fields.count)
                                XCTAssertEqual(0, queryResult.nodes.count)
                                XCTAssertEqual(0, queryResult.relationships.count)
                                XCTAssertEqual(0, queryResult.paths.count)
                                XCTAssertEqual(0, queryResult.rows.count)
                            }
                        }
                    } else {
                        XCTFail("Query failed somehow")
                    }

                }

                XCTAssertTrue(result.isSuccess)
            }

            exp.fulfill()
        }

        if let bookmark = client.getBookmark() {
            XCTAssertNotEqual("", bookmark)

            #if swift(>=4.0)
                let endIndex = bookmark.index(bookmark.startIndex, offsetBy: 17)
                let substring = bookmark[..<endIndex]
                XCTAssertEqual("neo4j:bookmark:v1", String(substring))
            #elseif swift(>=3.0)
                XCTAssertEqual("neo4j:bookmark:v1", bookmark.substring(to: bookmark.index(bookmark.startIndex, offsetBy: 17)))
            #endif

        } else {
            XCTFail("Bookmark should not be nil")
        }

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testGettingStartedExample() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testGettingStartedExample")

        // First, lets determine the number of existing King Arthurs. The test may have been run before

        let figureOutNumberOfKingArthurs = DispatchGroup()
        figureOutNumberOfKingArthurs.enter()
        var numberOfKingArthurs = -1

        client.executeCypher("MATCH (a:Person) WHERE a.name = {name} RETURN count(a) AS count", params: ["name": "Arthur"])  { result in

            XCTAssertTrue(result.isSuccess)
            XCTAssertTrue(result.value!.0)

            client.pullAll(partialQueryResult: result.value!.1) { response in
                switch result {
                case .failure:
                    XCTFail("Failed to pull response data")
                case let .success((success, queryResult)):
                    XCTAssertTrue(success)
                    XCTAssertEqual(1, queryResult.rows.count)
                    XCTAssertEqual(1, queryResult.rows.first!.count)
                    XCTAssertEqual(0, queryResult.nodes.count)
                    XCTAssertEqual(0, queryResult.relationships.count)
                    XCTAssertEqual(0, queryResult.paths.count)
                    XCTAssertEqual(1, queryResult.fields.count)

                    numberOfKingArthurs = Int(queryResult.rows.first?["count"] as! UInt64)
                    XCTAssertGreaterThanOrEqual(0, numberOfKingArthurs)

                }


                figureOutNumberOfKingArthurs.leave()
            }
        }
        figureOutNumberOfKingArthurs.wait()
        XCTAssertNotEqual(-1, numberOfKingArthurs)

        // Now lets run the actual test

        try client.executeAsTransaction() { (tx) in
            let result = client.executeCypherSync("CREATE (a:Person {name: {name}, title: {title}})",
                                                   params: ["name": "Arthur", "title": "King"])
            XCTAssertTrue(result.isSuccess)
            let queryResult = result.value!
            XCTAssertEqual(2, queryResult.stats.propertiesSetCount)
            XCTAssertEqual(1, queryResult.stats.labelsAddedCount)
            XCTAssertEqual(1, queryResult.stats.nodesCreatedCount)
            XCTAssertEqual("w", queryResult.stats.type)
            XCTAssertEqual(0, queryResult.fields.count)
            XCTAssertEqual(0, queryResult.nodes.count)
            XCTAssertEqual(0, queryResult.relationships.count)
            XCTAssertEqual(0, queryResult.paths.count)
            XCTAssertEqual(0, queryResult.rows.count)


            client.executeCypher("MATCH (a:Person) WHERE a.name = {name} " +
            "RETURN a.name AS name, a.title AS title", params: ["name": "Arthur"])  { result in

                XCTAssertTrue(result.isSuccess)
                XCTAssertTrue(result.value!.0)
                let queryResult = result.value!.1

                XCTAssertEqual(2, queryResult.fields.count)
                XCTAssertEqual(0, queryResult.nodes.count)
                XCTAssertEqual(0, queryResult.relationships.count)
                XCTAssertEqual(0, queryResult.paths.count)
                XCTAssertEqual(0, queryResult.rows.count)

                client.pullAll(partialQueryResult: queryResult) { result in

                    switch result {
                    case .failure(_):
                        XCTFail("Failed to pull response data")
                    case let.success((success, queryResult)):
                        XCTAssertTrue(success)

                        XCTAssertEqual("r", queryResult.stats.type)
                        XCTAssertEqual(2, queryResult.fields.count)
                        XCTAssertEqual(0, queryResult.nodes.count)
                        XCTAssertEqual(0, queryResult.relationships.count)
                        XCTAssertEqual(0, queryResult.paths.count)
                        XCTAssertEqual(1, queryResult.rows.count)
                        let row = queryResult.rows.first!
                        XCTAssertEqual(2, row.count)
                        XCTAssertEqual("King", row["title"] as! String)
                        XCTAssertEqual("Arthur", row["name"] as! String)


                        XCTAssertEqual(numberOfKingArthurs + 2, queryResult.rows.first?.count ?? 0)

                        tx.markAsFailed() // This should undo the beginning CREATE even though we have pulled it here
                        exp.fulfill()
                    }
                }
            }
        }

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testCreateAndRunCypherFromNode() throws {

        let node = Node(labels: ["Person","Husband","Father"], properties: [
            "firstName": "Niklas",
            "age": 38,
            "weight": 80.2,
            "favouriteWhiskys": List(items: ["Ardbeg", "Caol Ila", "Laphroaig"])
            ])

        let client = try makeClient()
        let result = client.createAndReturnNodeSync(node: node)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(resultNode):
            XCTAssertEqual(3, resultNode.labels.count)
            XCTAssertEqual(4, resultNode.properties.count)
            XCTAssertEqual("Niklas", resultNode.properties["firstName"] as! String)
            XCTAssertEqual(38 as Int64, resultNode.properties["age"]?.intValue())
        }
    }

    func makeSomeNodes() -> [Node] {
        let node1 = Node(labels: ["Person","Husband","Father"], properties: [
            "firstName": "Niklas",
            "age": 38,
            "weight": 80.2,
            "favouriteWhiskys": List(items: ["Ardbeg", "Caol Ila", "Laphroaig"])
            ])

        let node2 = Node(labels: ["Person","Wife","Mother"], properties: [
            "firstName": "Christina",
            "age": 37,
            "favouriteAnimals": List(items: ["Silver", "Oscar", "Simba"])
            ])

        return [node1, node2]
    }

    func testCreateAndRunCypherFromNodesWithResult() throws {

        let nodes = makeSomeNodes()

        let client = try makeClient()
        let result = client.createAndReturnNodesSync(nodes: nodes)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(resultNodes):
            var resultNode = resultNodes.filter { $0.properties["firstName"] as! String == "Niklas" }.first!
            XCTAssertEqual(3, resultNode.labels.count)
            XCTAssertTrue(resultNode.labels.contains("Father"))
            XCTAssertEqual(4, resultNode.properties.count)
            XCTAssertEqual("Niklas", resultNode.properties["firstName"] as! String)
            XCTAssertEqual(38 as Int64, resultNode.properties["age"]?.intValue())

            resultNode = resultNodes.filter { $0.properties["firstName"] as! String == "Christina" }.first!
            XCTAssertEqual(3, resultNode.labels.count)
            XCTAssertTrue(resultNode.labels.contains("Mother"))
            XCTAssertEqual(3, resultNode.properties.count)
            XCTAssertEqual("Christina", resultNode.properties["firstName"] as! String)
            XCTAssertEqual(37 as Int64, resultNode.properties["age"]?.intValue())
        }
    }

    func testUpdateAndRunCypherFromNodesWithResult() throws {

        let nodes = makeSomeNodes()

        let client = try makeClient()
        var result = client.createAndReturnNodesSync(nodes: nodes)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case var .success(resultNodes):
            let resultNode = resultNodes.filter { $0.properties["firstName"] as! String == "Niklas" }.first!
            let resultNode2 = resultNodes.filter { $0.properties["firstName"] as! String == "Christina" }.first!

            resultNode["instrument"] = "Recorder"
            resultNode["favouriteComposer"] = "CPE Bach"
            resultNode["weight"] = nil
            resultNode.add(label: "LabelledOne")

            resultNode2["instrument"] = "Piano"
            resultNode2.add(label: "LabelledOne")
            result = client.updateAndReturnNodesSync(nodes: [resultNode, resultNode2])
            XCTAssertNotNil(result.value)
            resultNodes = result.value!

            let resultNode3 = resultNodes.filter { $0.properties["firstName"] as! String == "Niklas" }.first!
            XCTAssertEqual(4, resultNode3.labels.count)
            XCTAssertTrue(resultNode3.labels.contains("Father"))
            XCTAssertTrue(resultNode3.labels.contains("LabelledOne"))
            XCTAssertEqual(5, resultNode3.properties.count)
            XCTAssertNil(resultNode3["weight"])
            XCTAssertEqual("Niklas", resultNode3.properties["firstName"] as! String)
            XCTAssertEqual(38 as Int64, resultNode3.properties["age"]?.intValue())

            let resultNode4 = resultNodes.filter { $0.properties["firstName"] as! String == "Christina" }.first!
            XCTAssertEqual(4, resultNode4.labels.count)
            XCTAssertTrue(resultNode4.labels.contains("Mother"))
            XCTAssertTrue(resultNode4.labels.contains("LabelledOne"))
            XCTAssertEqual(4, resultNode4.properties.count)
            XCTAssertEqual("Christina", resultNode4.properties["firstName"] as! String)
            XCTAssertEqual(37 as Int64, resultNode4.properties["age"]?.intValue())

        }
    }

    func testUpdateAndRunCypherFromNodesWithoutResult() throws {

        let nodes = makeSomeNodes()

        let client = try makeClient()
        let result = client.createAndReturnNodesSync(nodes: nodes)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(resultNodes):
            let resultNode = resultNodes.filter { $0.properties["firstName"] as! String == "Niklas" }.first!
            let resultNode2 = resultNodes.filter { $0.properties["firstName"] as! String == "Christina" }.first!

            resultNode["instrument"] = "Recorder"
            resultNode["favouriteComposer"] = "CPE Bach"
            resultNode["weight"] = nil
            resultNode.add(label: "LabelledOne")

            resultNode2["instrument"] = "Piano"
            resultNode2.add(label: "LabelledOne")
            let result = client.updateNodesSync(nodes: [resultNode, resultNode2])
            XCTAssertNotNil(result.value)
            XCTAssertTrue(result.value!)
        }
    }
    
    func testUpdateNode() throws {
        let client = try makeClient()

        var apple = Node(labels: ["Fruit"], properties: [:])
        apple["pits"] = 4
        apple["color"] = "green"
        apple["variety"] = "McIntosh"
        let createResult = client.createAndReturnNodeSync(node: apple)
        XCTAssertTrue(createResult.isSuccess)

        apple = createResult.value!
        apple.add(label: "Apple")
        apple["juicy"] = true
        apple["findMe"] = 42
        let updateResult = client.updateNodeSync(node: apple)
        XCTAssertTrue(updateResult.isSuccess)
        
        let prevId = apple.id!
        let exp = expectation(description: "Should get expected update back")
        client.nodeBy(id: prevId) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value as? Node)
            let apple = result.value!!
            
            XCTAssertNotNil(apple.id)
            XCTAssertEqual(prevId, apple.id!)
            XCTAssertEqual(42, apple["findMe"]?.intValue() ?? -1)
            XCTAssertTrue(apple["juicy"] as? Bool ?? false)
            XCTAssertTrue(apple.labels.contains("Apple"))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
        
    }
    
    func testUpdateAndReturnNode() throws {
        let client = try makeClient()
        
        var apple = Node(labels: ["Fruit"], properties: [:])
        apple["pits"] = 4
        apple["color"] = "green"
        apple["variety"] = "McIntosh"
        let createResult = client.createAndReturnNodeSync(node: apple)
        XCTAssertTrue(createResult.isSuccess)
        
        apple = createResult.value!
        apple.add(label: "Apple")
        apple["juicy"] = true
        apple["findMe"] = 42
        
         let updateResult = client.updateAndReturnNodeSync(node: apple)
         XCTAssertNotNil(apple.id)
         XCTAssertTrue(updateResult.isSuccess)
         XCTAssertNotNil(updateResult.value)
         apple = updateResult.value!
         XCTAssertEqual(42, apple["findMe"]?.intValue() ?? -1)
         XCTAssertTrue(apple["juicy"] as? Bool ?? false)
         XCTAssertTrue(apple.labels.contains("Apple"))
    }
    
    func testCypherMatching() throws {
        let client = try makeClient()
        let cypher =
          """
          MATCH (n)-->(m)
          RETURN n, count(1)
          """
        let cypherResult = client.executeCypherSync(cypher)
        XCTAssertTrue(cypherResult.isSuccess)

    }

    func testCreateAndRunCypherFromNodesNoResult() throws {

        let nodes = makeSomeNodes()

        let client = try makeClient()
        let result = client.createNodesSync(nodes: nodes)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(isSuccess):
            XCTAssertTrue(isSuccess)
        }

    }
    
    func testCreatePropertylessNodeAsync() throws {
        
        let node = Node(label: "Juice", properties: [:])
        let exp = expectation(description: "testCreatePropertylessNodeAsync")
        
        let client = try makeClient()
        client.createNode(node: node) { (result) in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(isSuccess):
                XCTAssertTrue(isSuccess)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }

    func testCreateAndRunCypherFromNodeNoResult() throws {

        let nodes = makeSomeNodes()

        let client = try makeClient()
        let result = client.createNodeSync(node: nodes.first!)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(isSuccess):
            XCTAssertTrue(isSuccess)
        }
    }
    
    func testUpdateNodesWithResult() throws {

        let node = makeSomeNodes().first!
        let client = try makeClient()
        var result = client.createAndReturnNodeSync(node: node)
        let createdNode = result.value!

        createdNode["favouriteColor"] = "Blue"
        createdNode["luckyNumber"] = 24
        createdNode.add(label: "RecorderPlayer")

        result = client.updateAndReturnNodeSync(node: createdNode)
        let updatedNode = result.value!

        XCTAssertEqual(4, updatedNode.labels.count)
        XCTAssertEqual(Int64(24), updatedNode["luckyNumber"]!.intValue()!)
    }

    func testUpdateNodesWithNoResult() throws {

        let node = makeSomeNodes().first!
        let client = try makeClient()
        let result = client.createAndReturnNodeSync(node: node)
        let createdNode = result.value!

        createdNode["favouriteColor"] = "Blue"
        createdNode["luckyNumber"] = 24
        createdNode.add(label: "RecorderPlayer")

        let emptyResult = client.updateNodeSync(node: createdNode)
        let isSuccess = emptyResult.value!
        XCTAssertTrue(isSuccess)
    }

    func testCreateRelationshipWithoutCreateNodes() throws {
        
        let client = try makeClient()
        let nodes = makeSomeNodes()
        let createdNodes = client.createAndReturnNodesSync(nodes: nodes).value!
        var (from, to) = (createdNodes[0], createdNodes[1])
        var result = client.relateSync(node: from, to: to, type: "Married to")
        if !result.isSuccess {
            XCTFail("Creating relationship failed!")
        }
        
        result = client.relateSync(node: from, to: to, type: "Married to", properties: [ "happily": true ])
        let createdRelationship: Relationship = result.value!
        
        XCTAssertTrue(createdRelationship["happily"] as! Bool)
        XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
        XCTAssertEqual(to.id!, createdRelationship.toNodeId)
        
        from = createdRelationship.fromNode!
        to = createdRelationship.toNode!
        XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
        XCTAssertEqual(to.id!, createdRelationship.toNodeId)
    }
    
    func testCreateRelationshipWithCreateNodes() throws {
        
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        var (from, to) = (madeNodes[0], madeNodes[1])
        let result = client.relateSync(node: from, to: to, type: "Married to", properties: [ "happily": true ])
        let createdRelationship: Relationship = result.value!
        
        XCTAssertTrue(createdRelationship["happily"] as! Bool)
        
        from = createdRelationship.fromNode!
        to = createdRelationship.toNode!
        XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
        XCTAssertEqual(to.id!, createdRelationship.toNodeId)
    }
    
    func testCreateRelationshipWithCreateFromNode() throws {
        
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        var (from_, to) = (madeNodes[0], madeNodes[1])
        let createdNode = client.createAndReturnNodeSync(node: from_).value!
        var from = createdNode
        let result = client.relateSync(node: from, to: to, type: "Married to", properties: [ "happily": true ])
        let createdRelationship: Relationship = result.value!
        
        XCTAssertTrue(createdRelationship["happily"] as! Bool)
        XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
        
        from = createdRelationship.fromNode!
        to = createdRelationship.toNode!
        XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
        XCTAssertEqual(to.id!, createdRelationship.toNodeId)
    }
    
    func testCreateAndReturnRelationshipsSync() throws {
        
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        let (from, to) = (madeNodes[0], madeNodes[1])
        let relationship1 = Relationship(fromNode: from, toNode: to, type: "Married to")
        let relationship2 = Relationship(fromNode: to, toNode: from, type: "Married to")
        let createdRelationships = client.createAndReturnRelationshipsSync(relationships: [relationship1, relationship2])
        XCTAssertTrue(createdRelationships.isSuccess)
        XCTAssertEqual(2, createdRelationships.value!.count)
    }
    
    func testCreateAndReturnRelationships() throws {
        
        let exp = expectation(description: "testCreateAndReturnRelationships")
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        let (from, to) = (madeNodes[0], madeNodes[1])
        let relationship1 = Relationship(fromNode: from, toNode: to, type: "Married to")
        let relationship2 = Relationship(fromNode: to, toNode: from, type: "Married to")
        client.createAndReturnRelationships(relationships: [relationship1, relationship2]) { createdRelationships in
            XCTAssertTrue(createdRelationships.isSuccess)
            XCTAssertEqual(2, createdRelationships.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCreateAndReturnRelationship() throws {
        
        let exp = expectation(description: "testCreateAndReturnRelationships")
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        let (from, to) = (madeNodes[0], madeNodes[1])
        let relationship = Relationship(fromNode: from, toNode: to, type: "Married to")
        client.createAndReturnRelationship(relationship: relationship) { createdRelationships in
            XCTAssertTrue(createdRelationships.isSuccess)
            XCTAssertEqual("Married to", createdRelationships.value!.type)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCreateAndReturnRelationshipByCreatingFromAndToNode() throws {
        
        let exp = expectation(description: "testCreateAndReturnRelationships")
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        let (from_, to_) = (madeNodes[0], madeNodes[1])
        
        guard
            let from = client.createAndReturnNodeSync(node: from_).value,
            let to = client.createAndReturnNodeSync(node: to_).value
        else {
            XCTFail("Failed while creating nodes")
            return
        }

        let relationship = Relationship(fromNode: from, toNode: to, type: "Married to")
        client.createAndReturnRelationship(relationship: relationship) { createdRelationships in
            
            if case Result.failure(let error) = createdRelationships {
                XCTFail("Did not expect creation of relationship to fail. Got error \(error)")
            }
            
            XCTAssertTrue(createdRelationships.isSuccess)
            XCTAssertEqual("Married to", createdRelationships.value!.type)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCreateAndReturnRelationshipByCreatingOnlyFromNode() throws {
        
        let exp = expectation(description: "testCreateAndReturnRelationships")
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        let (from_, to) = (madeNodes[0], madeNodes[1])
        
        guard
            let from = client.createAndReturnNodeSync(node: from_).value
            else {
                XCTFail("Failed while creating nodes")
                return
        }
        
        let relationship = Relationship(fromNode: from, toNode: to, type: "Married to")
        client.createAndReturnRelationship(relationship: relationship) { createdRelationships in
            
            if case Result.failure(let error) = createdRelationships {
                XCTFail("Did not expect creation of relationship to fail. Got error \(error)")
            }
            
            XCTAssertTrue(createdRelationships.isSuccess)
            XCTAssertEqual("Married to", createdRelationships.value!.type)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }

    func testCreateAndReturnRelationshipByCreatingOnlyToNode() throws {
        
        let exp = expectation(description: "testCreateAndReturnRelationships")
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        let (from, to_) = (madeNodes[0], madeNodes[1])
        
        guard
            let to = client.createAndReturnNodeSync(node: to_).value
            else {
                XCTFail("Failed while creating nodes")
                return
        }
        
        let relationship = Relationship(fromNode: from, toNode: to, type: "Married to")
        client.createAndReturnRelationship(relationship: relationship) { createdRelationships in
            
            if case Result.failure(let error) = createdRelationships {
                XCTFail("Did not expect creation of relationship to fail. Got error \(error)")
            }
            
            XCTAssertTrue(createdRelationships.isSuccess)
            XCTAssertEqual("Married to", createdRelationships.value!.type)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCreateRelationshipWithCreateToNode() throws {
        
        let client = try makeClient()
        let madeNodes = makeSomeNodes()
        var (from, to_) = (madeNodes[0], madeNodes[1])
        let createdNode = client.createAndReturnNodeSync(node: to_).value!
        var to = createdNode
        let result = client.relateSync(node: from, to: to, type: "Married to", properties: [ "happily": true ])
        let createdRelationship: Relationship = result.value!
        
        if case Result.failure(let resultError) = result {
            XCTFail("Did not expect error \(resultError)")
        }

        XCTAssertTrue(createdRelationship["happily"] as! Bool)
        XCTAssertEqual(to.id!, createdRelationship.toNodeId)
        
        from = createdRelationship.fromNode!
        to = createdRelationship.toNode!
        XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
        XCTAssertEqual(to.id!, createdRelationship.toNodeId)
    }
    
    func testCreateRelationshipSync() throws {
        let client = try makeClient()
        let nodes = makeSomeNodes()

        let reader: Node! = nodes[0]
        let writer: Node! = nodes[1]
        var relationship = Relationship(fromNode: reader, toNode: writer, type: "follows")
        let result = client.createAndReturnRelationshipSync(relationship: relationship)
        XCTAssertTrue(result.isSuccess)
        relationship = result.value!
        XCTAssertEqual("follows", relationship.type)
        //XCTAssertEqual(reader.labels, relationship.fromNode?.labels ?? [])
        //XCTAssertEqual(writer.labels, relationship.toNode?.labels ?? [])
    }

    func testCreateRelationshipsWithExistingNodesUsingId() throws {
        
        let client = try makeClient()
        let nodes = makeSomeNodes()
        let createdNodes = client.createAndReturnNodesSync(nodes: nodes).value!
        let (from, to) = (createdNodes[0], createdNodes[1])
        
        guard let fromId = from.id,
            let toId = to.id
            else {
                XCTFail()
                return
        }
        
        let rel1 = Relationship(fromNodeId: fromId, toNodeId: toId, type: "Married to", direction: .to, properties: [ "happily": true ])
        let rel2 = Relationship(fromNodeId: fromId, toNodeId: toId, type: "Married to", direction: .from, properties: [ "happily": true ])
        
        let request = [rel1, rel2].createRequest(withReturnStatement: true)
        var queryResult: QueryResult! = nil
        let group = DispatchGroup()
        group.enter()
        client.executeWithResult(request: request) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
                return
            case let .success((isSuccess, theQueryResult)):
                XCTAssertTrue(isSuccess)
                queryResult = theQueryResult
            }
            group.leave()
        }
        group.wait()
        
        XCTAssertEqual(1, queryResult!.rows.count)
        XCTAssertEqual(4, queryResult!.fields.count)
        XCTAssertEqual(2, queryResult!.nodes.count)
        XCTAssertEqual(2, queryResult!.relationships.count)
        XCTAssertEqual("rw", queryResult!.stats.type)
    }

    func testCreateRelationshipsWithExistingNodesUsingNode() throws {

        let client = try makeClient()
        let nodes = makeSomeNodes()
        let createdNodes = client.createAndReturnNodesSync(nodes: nodes).value!
        let (from, to) = (createdNodes[0], createdNodes[1])

        let rel1 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .to, properties: [ "happily": true ])
        let rel2 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .from, properties: [ "happily": true ])

        let request = [rel1, rel2].createRequest(withReturnStatement: true)
        var queryResult: QueryResult! = nil
        let group = DispatchGroup()
        group.enter()
        client.executeWithResult(request: request) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
                return
            case let .success((isSuccess, theQueryResult)):
                XCTAssertTrue(isSuccess)
                queryResult = theQueryResult
            }
            group.leave()
        }
        group.wait()

        XCTAssertEqual(1, queryResult!.rows.count)
        XCTAssertEqual(4, queryResult!.fields.count)
        XCTAssertEqual(2, queryResult!.nodes.count)
        XCTAssertEqual(2, queryResult!.relationships.count)
        XCTAssertEqual("rw", queryResult!.stats.type)
    }
    
    func testCreateRelationshipsWithoutExistingNodes() throws {
        
        let client = try makeClient()
        let nodes = makeSomeNodes()
        let (from, to) = (nodes[0], nodes[1])
        
        let rel1 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .to, properties: [ "happily": true ])
        let rel2 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .from, properties: [ "happily": true ])
        
        let request = [rel1, rel2].createRequest(withReturnStatement: true)
        var queryResult: QueryResult! = nil
        let group = DispatchGroup()
        group.enter()
        client.executeWithResult(request: request) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
                return
            case let .success((isSuccess, theQueryResult)):
                XCTAssertTrue(isSuccess)
                queryResult = theQueryResult
            }
            group.leave()
        }
        group.wait()

        XCTAssertEqual(1, queryResult!.rows.count)
        XCTAssertEqual(4, queryResult!.fields.count)
        XCTAssertEqual(2, queryResult!.nodes.count)
        XCTAssertEqual(2, queryResult!.relationships.count)
        XCTAssertEqual("rw", queryResult!.stats.type)
    }
    
    func testCreateRelationshipsWithMixedNodes() throws {
        
        let client = try makeClient()
        let nodes = makeSomeNodes()
        let (from_, to) = (nodes[0], nodes[1])
        let from = client.createAndReturnNodeSync(node: from_).value!
        
        let rel1 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .to, properties: [ "happily": true ])
        let rel2 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .from, properties: [ "happily": true ])

        let request = [rel1, rel2].createRequest(withReturnStatement: true)
        var queryResult: QueryResult! = nil
        let group = DispatchGroup()
        group.enter()
        client.executeWithResult(request: request) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
                return
            case let .success((isSuccess, theQueryResult)):
                XCTAssertTrue(isSuccess)
                queryResult = theQueryResult
            }
            group.leave()
        }
        group.wait()
        
        XCTAssertEqual(1, queryResult!.rows.count)
        XCTAssertEqual(4, queryResult!.fields.count)
        XCTAssertEqual(2, queryResult!.nodes.count)
        XCTAssertEqual(2, queryResult!.relationships.count)
        XCTAssertEqual("rw", queryResult!.stats.type)
    }

    func testUpdateRelationship() throws {

        let exp = expectation(description: "Finish transaction with updates to relationship")
        let client = try makeClient()
        try client.executeAsTransaction() { tx in

            let nodes = self.makeSomeNodes()
            let createdNodes = client.createAndReturnNodesSync(nodes: nodes).value!
            let (from, to) = (createdNodes[0], createdNodes[1])
            var result = client.relateSync(node: from, to: to, type: "Married", properties: [ "happily": true ])
            let createdRelationship: Relationship = result.value!

            XCTAssertTrue(createdRelationship["happily"] as! Bool)
            XCTAssertEqual(from.id!, createdRelationship.fromNodeId)
            XCTAssertEqual(to.id!, createdRelationship.toNodeId)

            createdRelationship["location"] = "church"
            createdRelationship["someProp"] = 42
            result = client.updateAndReturnRelationshipSync(relationship: createdRelationship)
            let updatedRelationship: Relationship = result.value!

            updatedRelationship["someProp"] = nil
            result = client.updateAndReturnRelationshipSync(relationship: updatedRelationship)
            let finalRelationship: Relationship = result.value!

            XCTAssertTrue(finalRelationship["happily"] as! Bool)
            XCTAssertEqual("church", finalRelationship["location"] as! String)
            XCTAssertNil(finalRelationship["someProp"])
            XCTAssertEqual(from.id!, finalRelationship.fromNodeId)
            XCTAssertEqual(to.id!, finalRelationship.toNodeId)

            tx.markAsFailed()
            exp.fulfill()
        }

        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testCreateAndDeleteNode() throws {

        let node = makeSomeNodes().first!

        let client = try makeClient()
        let result = client.createAndReturnNodeSync(node: node)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(resultNode):
            let result = client.deleteNodeSync(node: resultNode)
            switch result{
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(isSuccess):
                XCTAssertTrue(isSuccess)
            }
        }
    }

    func testCreateAndDeleteNodes() throws {

        let nodes = makeSomeNodes()

        let client = try makeClient()
        let result = client.createAndReturnNodesSync(nodes: nodes)
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case let .success(resultNodes):
            let result = client.deleteNodesSync(nodes: resultNodes)
            switch result{
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(isSuccess):
                XCTAssertTrue(isSuccess)
            }
        }
    }

    func testUpdateRelationshipNoReturn() throws {

        var from = Node(labels: ["Candidate"], properties: ["name": "Bala"])
        var to = Node(labels: ["Employer"], properties: ["name": "Yahoo"])

        let client = try makeClient()
        let result = client.createAndReturnNodesSync(nodes: [from, to])
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.value)
        let resultNodes = result.value!
        from = resultNodes[0]
        to = resultNodes[1]

        let relResult = client.relateSync(node: from, to: to, type: "WORKED_IN", properties: [ "from": 2015, "to": 2017])
        XCTAssertTrue(relResult.isSuccess)
        XCTAssertNotNil(relResult.value)
        let relationship = relResult.value!

        relationship["to"] = 2016
        var updateRelResult = client.updateRelationshipSync(relationship: relationship)
        XCTAssertTrue(updateRelResult.isSuccess)
        XCTAssertNotNil(updateRelResult.value)
        XCTAssertTrue(updateRelResult.value!)
        
        relationship["to"] = 2018
        updateRelResult = client.updateRelationshipSync(relationship: relationship)
        XCTAssertTrue(updateRelResult.isSuccess)
        XCTAssertNotNil(updateRelResult.value)
        XCTAssertTrue(updateRelResult.value!)

    }

    func testDeleteRelationship() throws {

        var from = Node(labels: ["Candidate"], properties: ["name": "Bala"])
        var to = Node(labels: ["Employer"], properties: ["name": "Yahoo"])

        let client = try makeClient()
        let result = client.createAndReturnNodesSync(nodes: [from, to])
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.value)
        let resultNodes = result.value!
        from = resultNodes[0]
        to = resultNodes[1]

        let relResult = client.relateSync(node: from, to: to, type: "WORKED_IN", properties: [ "from": 2015, "to": 2017])
        XCTAssertTrue(relResult.isSuccess)
        XCTAssertNotNil(relResult.value)
        let relationship = relResult.value!

        let rmResult = client.deleteRelationshipSync(relationship: relationship)
        XCTAssertTrue(rmResult.isSuccess)

    }

    func testReturnPath() throws {

        try testIntroToCypher() // First make sure we have a result path

        let client = try makeClient()
        let query = "MATCH p = (a)-[*3..5]->(b)\nRETURN p LIMIT 5"
        let result = client.executeCypherSync(query)
        XCTAssertNotNil(result.value)
        XCTAssertEqual(1, result.value!.paths.count)
        let path = result.value!.paths.first!
        XCTAssertLessThan(0, path.segments.count)
    }

    func testBreweryDataset() throws {
        
        let indexQueries =
"""
CREATE INDEX ON :BeerBrand(name);
CREATE INDEX ON :Brewery(name);
CREATE INDEX ON :BeerType(name);
CREATE INDEX ON :AlcoholPercentage(value);
"""
        
        let queries =
"""
LOAD CSV WITH HEADERS FROM "https://docs.google.com/spreadsheets/d/1FwWxlgnOhOtrUELIzLupDFW7euqXfeh8x3BeiEY_sbI/export?format=csv&id=1FwWxlgnOhOtrUELIzLupDFW7euqXfeh8x3BeiEY_sbI&gid=0" AS CSV
WITH CSV AS beercsv
WHERE beercsv.BeerType IS not NULL
MERGE (b:BeerType {name: beercsv.BeerType})
WITH beercsv
WHERE beercsv.BeerBrand IS not NULL
MERGE (b:BeerBrand {name: beercsv.BeerBrand})
WITH beercsv
WHERE beercsv.Brewery IS not NULL
MERGE (b:Brewery {name: beercsv.Brewery})
WITH beercsv
WHERE beercsv.AlcoholPercentage IS not NULL
MERGE (b:AlcoholPercentage {value:
tofloat(replace(replace(beercsv.AlcoholPercentage,'%',''),',','.'))})
WITH beercsv
MATCH (ap:AlcoholPercentage {value:
tofloat(replace(replace(beercsv.AlcoholPercentage,'%',''),',','.'))}),
(br:Brewery {name: beercsv.Brewery}),
(bb:BeerBrand {name: beercsv.BeerBrand}),
(bt:BeerType {name: beercsv.BeerType})
CREATE (bb)-[:HAS_ALCOHOLPERCENTAGE]->(ap),
(bb)-[:IS_A]->(bt),
(bb)<-[:BREWS]-(br);
"""
        let client = try makeClient()
        for query in indexQueries.split(separator: ";") {
            let result = client.executeCypherSync(String(query))
            XCTAssertTrue(result.isSuccess)
        }
        
        try client.executeAsTransaction() { tx in
            for query in queries.split(separator: ";") {
                let result = client.executeCypherSync(String(query))
                XCTAssertTrue(result.isSuccess)
            }
            
            tx.markAsFailed()
        }
    }
    
    func testDisconnect() throws {
        let client = try makeClient()
        client.disconnect()
        let result = client.executeCypherSync("RETURN 1")
        XCTAssertFalse(result.isSuccess)
    }

    func testRecord() throws {
        let client = try makeClient()
        let result = client.executeCypherSync("RETURN 1,2,3")
        XCTAssertTrue(result.isSuccess)
        let row = result.value!.rows[0]
        XCTAssertEqual(1 as UInt64, row["1"]! as! UInt64)
        XCTAssertEqual(2 as UInt64, row["2"]! as! UInt64)
        XCTAssertEqual(3 as UInt64, row["3"]! as! UInt64)
    }
    
    func testFindNodeById() throws {
        
        let nodes = makeSomeNodes()
        
        let client = try makeClient()
        let createResult = client.createAndReturnNodeSync(node: nodes.first!)
        XCTAssertTrue(createResult.isSuccess)
        let createdNode = createResult.value!
        let createdNodeId = createdNode.id!

        client.nodeBy(id: createdNodeId) { foundNodeResult in
            switch foundNodeResult {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(foundNode):
                XCTAssertNotNil(foundNode)
                XCTAssertEqual(createdNode, foundNode!)
            }
        }
    }
    
    func testFindNodeByLabels() throws {
        let client = try makeClient()
        let nodes = makeSomeNodes()
        let labels = Array<String>(nodes.flatMap { $0.labels }[1...2]) // Husband, Father
        
        let group = DispatchGroup()
        group.enter()
        
        var nodeCount: Int = -1
        client.nodesWith(labels: labels, skip: 0, limit: 0) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            nodeCount = result.value!.count
            group.leave()
        }
        group.wait()
        
        let createResult = client.createNodeSync(node: nodes[0])
        XCTAssertTrue(createResult.isSuccess)
        
        let exp = expectation(description: "Node should be one more than on previous count")
        client.nodesWith(labels: labels, skip: 0, limit: 0) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(nodeCount + 1, result.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }

    func testFindNodeByProperties() throws {
        let client = try makeClient()
        let properties: [String:PackProtocol] = [
            "firstName": "Niklas",
            "age": 38
        ]
        
        let group = DispatchGroup()
        group.enter()
        
        var nodeCount: Int = -1
        client.nodesWith(properties: properties, skip: 0, limit: 0) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            nodeCount = result.value!.count
            group.leave()
        }
        group.wait()
        
        let nodes = makeSomeNodes()
        let createResult = client.createNodeSync(node: nodes[0])
        XCTAssertTrue(createResult.isSuccess)
        
        let exp = expectation(description: "Node should be one more than on previous count")
        client.nodesWith(properties: properties, skip: 0, limit: 0) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(nodeCount + 1, result.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }

    func testFindNodeByLabelsAndProperties() throws {
        let client = try makeClient()
        let labels = ["Father", "Husband"]
        let properties: [String:PackProtocol] = [
            "firstName": "Niklas",
            "age": 38
        ]
        
        let group = DispatchGroup()
        group.enter()
        
        let limit: UInt64 = UInt64(Int32.max)
        var nodeCount: Int = -1
        client.nodesWith(labels: labels, andProperties: properties, skip: 0, limit: limit) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            nodeCount = result.value!.count
            group.leave()
        }
        group.wait()
        
        let nodes = makeSomeNodes()
        let createResult = client.createNodeSync(node: nodes[0])
        XCTAssertTrue(createResult.isSuccess)
        
        let exp = expectation(description: "Node should be one more than on previous count")
        client.nodesWith(labels: labels, andProperties: properties, skip: 0, limit: limit) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(nodeCount + 1, result.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }

    func testFindNodeByLabelAndProperties() throws {
        let client = try makeClient()
        let label = "Father"
        let properties: [String:PackProtocol] = [
            "firstName": "Niklas",
            "age": 38
        ]
        
        let group = DispatchGroup()
        group.enter()
        
        let limit: UInt64 = UInt64(Int32.max)
        var nodeCount: Int = -1
        client.nodesWith(label: label, andProperties: properties, skip: 0, limit: limit) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            nodeCount = result.value!.count
            group.leave()
        }
        group.wait()
        
        let nodes = makeSomeNodes()
        let createResult = client.createNodeSync(node: nodes[0])
        XCTAssertTrue(createResult.isSuccess)
        
        let exp = expectation(description: "Node should be one more than on previous count")
        client.nodesWith(label: label, andProperties: properties, skip: 0, limit: limit) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(nodeCount + 1, result.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFindNodeByLabelsAndProperty() throws {
        let client = try makeClient()
        let labels = ["Father", "Husband"]
        let property: [String:PackProtocol] = [
            "firstName": "Niklas"
        ]
        
        let group = DispatchGroup()
        group.enter()
        
        var nodeCount: Int = -1
        client.nodesWith(labels: labels, andProperties: property, skip: 0, limit: 0) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            nodeCount = result.value!.count
            group.leave()
        }
        group.wait()
        
        let nodes = makeSomeNodes()
        let createResult = client.createNodeSync(node: nodes[0])
        XCTAssertTrue(createResult.isSuccess)
        
        let exp = expectation(description: "Node should be one more than on previous count")
        client.nodesWith(labels: labels, andProperties: property, skip: 0, limit: 0) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(nodeCount + 1, result.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFindNodeByLabelAndProperty() throws {
        let client = try makeClient()
        let label = "Father"
        let property: [String:PackProtocol] = [
            "firstName": "Niklas"
        ]
        
        let group = DispatchGroup()
        group.enter()
        
        let limit: UInt64 = UInt64(Int32.max)
        var nodeCount: Int = -1
        client.nodesWith(label: label, andProperties: property, skip: 0, limit: limit) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            nodeCount = result.value!.count
            group.leave()
        }
        group.wait()
        
        let nodes = makeSomeNodes()
        let createResult = client.createNodeSync(node: nodes[0])
        XCTAssertTrue(createResult.isSuccess)
        
        let exp = expectation(description: "Node should be one more than on previous count")
        client.nodesWith(label: label, andProperties: property, skip: 0, limit: limit) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(nodeCount + 1, result.value!.count)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFindRelationshipsByType() throws {
        
        let client = try makeClient()
        let nodes = makeSomeNodes()
        
        let type = "IS_MADLY_IN_LOVE_WITH"
        let result = client.relateSync(node: nodes[0], to: nodes[1], type: type)
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.value)
        let relationship = result.value!
        
        let exp = expectation(description: "Found relationship in result")
        client.relationshipsWith(type: type) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            let relationships = result.value!
            for rel in relationships {
                if let foundId = rel.id,
                    let compareId = relationship.id,
                    foundId == compareId {
                    exp.fulfill()
                    break
                }
                
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }

    func testFindRelationshipsByTypeAndProperties() throws {
        let client = try makeClient()
        let nodes = makeSomeNodes()
        
        let type = "IS_MADLY_IN_LOVE_WITH"
        let props: [String: PackProtocol] = [ "propA": true, "propB": "another" ]
        let result = client.relateSync(node: nodes[0], to: nodes[1], type: type, properties: props )
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.value)
        let relationship = result.value!
        
        let exp = expectation(description: "Found relationship in result")
        client.relationshipsWith(type: type, andProperties: props) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            let relationships = result.value!
            for rel in relationships {
                if let foundId = rel.id,
                    let compareId = relationship.id,
                    foundId == compareId {
                    exp.fulfill()
                    break
                }
                
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFindRelationshipsByTypeAndProperty() throws {
        let client = try makeClient()
        let nodes = makeSomeNodes()
        
        let type = "IS_MADLY_IN_LOVE_WITH"
        let props: [String: PackProtocol] = [ "propA": true, "propB": "another" ]
        let result = client.relateSync(node: nodes[0], to: nodes[1], type: type, properties: props )
        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.value)
        let relationship = result.value!
        
        let exp = expectation(description: "Found relationship in result")
        client.relationshipsWith(type: type, andProperties: ["propA": true]) { result in
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.value)
            let relationships = result.value!
            for rel in relationships {
                if let foundId = rel.id,
                    let compareId = relationship.id,
                    foundId == compareId {
                    exp.fulfill()
                    break
                }
                
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    /// Expectation: nothing else runs on the database on the same time
    func testThatRelationshipsForExistingNodesDoNotCreateNewNodes() throws {

        let count: () throws -> (Int) = { [weak self] in
            guard let client = try self?.makeClient() else { return -3 }
            let query = "MATCH (n) RETURN count(n) AS count"
            let result = client.executeCypherSync(query)
            let ret: Int
            switch result {
            case .failure:
                ret = -1
            case let .success(queryResult):
                if let row = queryResult.rows.first,
                    let countValue = row["count"] as? UInt64 {
                    let countIntValue = Int(countValue)
                    ret = countIntValue
                } else {
                    ret = -2
                }
            }
            return ret
        }
        
        let client = try makeClient()
        let nodes = makeSomeNodes()
        let createdNodes = client.createAndReturnNodesSync(nodes: nodes).value!
        let (from, to) = (createdNodes[0], createdNodes[1])

        let before = try count()
        XCTAssertGreaterThan(before, -1)
        
        let rel1 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .to, properties: [ "happily": true ])
        let rel2 = Relationship(fromNode: from, toNode: to, type: "Married to", direction: .from, properties: [ "happily": true ])
        
        let request = [rel1, rel2].createRequest(withReturnStatement: true)
        var queryResult: QueryResult! = nil
        let group = DispatchGroup()
        group.enter()
        client.executeWithResult(request: request) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
                return
            case let .success((isSuccess, theQueryResult)):
                XCTAssertTrue(isSuccess)
                queryResult = theQueryResult
            }
            group.leave()
        }
        group.wait()
        
        XCTAssertEqual(1, queryResult!.rows.count)
        XCTAssertEqual(4, queryResult!.fields.count)
        XCTAssertEqual(2, queryResult!.nodes.count)
        XCTAssertEqual(2, queryResult!.relationships.count)
        XCTAssertEqual("rw", queryResult!.stats.type)
        
        let after = try count()
    
        XCTAssertEqual(before, after)
    }
    
    func createBigNodes(num: Int) throws {
        let query = "UNWIND RANGE(1, 16, 1) AS i CREATE (n:BigNode { i: i, payload: {payload} })"
        let payload = (0..<1024).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" } .joined(separator: "/0123456789/")
        
        let client = try makeClient()
        let result = client.executeCypherSync(query, params: ["payload": payload])
        switch result {
        case let .failure(error):
            XCTFail(error.localizedDescription)
        case .success(_):
            break
        }

    }
    
    func testMultiChunkResults() throws {
        try createBigNodes(num: 16)
        let exp = expectation(description: "Got lots of data back")

        let client = try makeClient()
        client.nodesWith(labels: ["BigNode"], andProperties: [:], skip:0, limit: 0) { result in
            switch result {
            case let .failure(error):
                XCTFail(error.localizedDescription)
            case let .success(nodes):
                XCTAssertGreaterThan(nodes.count, 0)
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 15.0) { (error) in
            XCTAssertNil(error)
        }
    }

    static var allTests = [
        ("testBreweryDataset", testBreweryDataset),
        ("testCancellingTransaction", testCancellingTransaction),
        ("testCreateAndDeleteNode", testCreateAndDeleteNode),
        ("testCreateAndDeleteNodes", testCreateAndDeleteNodes),
        ("testCreateAndRunCypherFromNode", testCreateAndRunCypherFromNode),
        ("testCreateAndRunCypherFromNodeNoResult", testCreateAndRunCypherFromNodeNoResult),
        ("testCreateAndRunCypherFromNodesNoResult", testCreateAndRunCypherFromNodesNoResult),
        ("testCreateAndRunCypherFromNodesWithResult", testCreateAndRunCypherFromNodesWithResult),
        ("testCreateRelationshipWithCreateFromNode", testCreateRelationshipWithCreateFromNode),
        ("testCreateRelationshipWithCreateNodes", testCreateRelationshipWithCreateNodes),
        ("testCreateRelationshipWithCreateToNode", testCreateRelationshipWithCreateToNode),
        ("testCreateRelationshipWithoutCreateNodes", testCreateRelationshipWithoutCreateNodes),
        ("testCreateRelationshipsWithExistingNodesUsingId", testCreateRelationshipsWithExistingNodesUsingId),
        ("testCreateRelationshipsWithExistingNodesUsingNode", testCreateRelationshipsWithExistingNodesUsingNode),
        ("testCreateRelationshipsWithMixedNodes", testCreateRelationshipsWithMixedNodes),
        ("testCreateRelationshipsWithoutExistingNodes", testCreateRelationshipsWithoutExistingNodes),
        ("testCypherMatching", testCypherMatching),
        ("testDeleteRelationship", testDeleteRelationship),
        ("testFailingTransactionSync", testFailingTransactionSync),
        ("testGettingStartedExample", testGettingStartedExample),
        ("testIntroToCypher", testIntroToCypher),
        ("testNodeResult", testNodeResult),
        ("testRelationshipResult", testRelationshipResult),
        ("testReturnPath", testReturnPath),
        ("testSetOfQueries", testSetOfQueries),
        ("testSucceedingTransactionSync", testSucceedingTransactionSync),
        ("testTransactionResultsInBookmark", testTransactionResultsInBookmark),
        ("testUpdateAndRunCypherFromNodesWithResult", testUpdateAndRunCypherFromNodesWithResult),
        ("testUpdateAndRunCypherFromNodesWithoutResult", testUpdateAndRunCypherFromNodesWithoutResult),
        ("testUpdateNode", testUpdateNode),
        ("testUpdateNodesWithNoResult", testUpdateNodesWithNoResult),
        ("testUpdateNodesWithResult", testUpdateNodesWithResult),
        ("testUpdateRelationship", testUpdateRelationship),
        ("testUpdateRelationshipNoReturn", testUpdateRelationshipNoReturn),
        ("testDisconnect", testDisconnect),
        ("testRecord", testRecord),
        ("testFindNodeById", testFindNodeById),
        ("testFindNodeByLabels", testFindNodeByLabels),
        ("testFindNodeByLabelsAndProperties", testFindNodeByLabelsAndProperties),
        ("testFindNodeByLabelAndProperties", testFindNodeByLabelAndProperties),
        ("testFindNodeByLabelsAndProperty", testFindNodeByLabelsAndProperty),
        ("testFindNodeByLabelAndProperty", testFindNodeByLabelAndProperty),
        ("testCreateAndReturnRelationshipsSync", testCreateAndReturnRelationshipsSync),
        ("testCreateAndReturnRelationships", testCreateAndReturnRelationships),
        ("testCreateAndReturnRelationship", testCreateAndReturnRelationship),
        ("testUpdateAndReturnNode", testUpdateAndReturnNode),
        ("testFindRelationshipsByType", testFindRelationshipsByType),
        ("testFindRelationshipsByTypeAndProperties", testFindRelationshipsByTypeAndProperties),
        ("testFindRelationshipsByTypeAndProperty", testFindRelationshipsByTypeAndProperty),
    ]

}

extension Result {
    var isSuccess: Bool {
        get {
            switch self {
            case .failure(_):
                return false
            case .success(_):
                return true
            }
        }
    }
}
