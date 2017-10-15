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

class Theo_001_BoltClientTests: XCTestCase {

    let configuration: BoltConfig = ConfigLoader.loadBoltConfig()


    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func performConnect(client: BoltClient, completionBlock: (() -> ())? = nil) {
//        let connectGroup = DispatchGroup()
//        connectGroup.enter()
        client.connect() { connectionResult in
            switch connectionResult {
            case let .failure(error):
                print("Oh no! \(error)")
//                print("Error connecting: \(error)")
//                if error.errorCode == -9806 {
//                    self.performConnect(client: client) {
//                        connectGroup.leave()
//                    }
//                } else {
//                    XCTFail()
//                    connectGroup.leave()
//                }
            case let .success(isConnected):
                if !isConnected {
                    print("Error, could not connect!")
                }
            }
//            connectGroup.leave()
        }
//        print("Waiting")
//        connectGroup.wait()
//        print("Done waiting")
    }

    private func makeClient() throws -> BoltClient {
        let client = try BoltClient(hostname: configuration.hostname,
                                    port: configuration.port,
                                    username: configuration.username,
                                    password: configuration.password,
                                    encrypted: configuration.encrypted)

        performConnect(client: client)

        print(" --- done connecting ---")
        return client
    }

    func testNodeResult() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testNodeResult")

        XCTAssertTrue(try client.executeCypherSync("MATCH (n:TheoTestNode { foo: \"bar\", baz: 3}) RETURN n").isSuccess)
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

        XCTAssertTrue(try client.executeCypherSync(query).isSuccess)
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
                      MATCH (expert)-[:WORKED_WITH]->(db:Database {name:"Neo4j"})
                      MATCH path = shortestPath( (you)-[:FRIEND*..5]-(expert) )
                      RETURN db,expert,path
                   """)

        for query in queries {
            print(query)
            XCTAssertTrue(try client.executeCypherSync(query).isSuccess)

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
        let client = try makeClient()
        let exp = self.expectation(description: "testCancellingTransaction")

        try client.executeAsTransaction() { (tx) in
            tx.markAsFailed()
            exp.fulfill()
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error)
        })

    }

    func testTransactionResultsInBookmark() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testTransactionResultsInBookmark")

        try client.executeAsTransaction() { (tx) in
            client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})") {
                XCTAssertTrue($0.isSuccess)
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

            client.pullAll() { result in
                switch result {
                case .failure:
                    XCTFail("Failed to pull response data")
                case let .success((success, response)):
                    XCTAssertTrue(success)
                    XCTAssertEqual(2, response.count)
                    if let theResponse = response[0].items[0] as? List,
                        let n = Int(theResponse.items[0]) {
                        numberOfKingArthurs = n
                    } else {
                        XCTFail("Response was not of the kind List")
                    }
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


            client.executeCypher("MATCH (a:Person) WHERE a.name = {name} " +
            "RETURN a.name AS name, a.title AS title", params: ["name": "Arthur"])  { result in

                XCTAssertTrue(result.isSuccess)

                client.pullAll() { result in

                    switch result {
                    case .failure(_):
                        XCTFail("Failed to pull response data")
                    case let.success((success, response)):
                        XCTAssertTrue(result.isSuccess)
                        XCTAssertEqual(numberOfKingArthurs + 2, response.count)

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

    static var allTests = [
        ("testSucceedingTransactionSync", testSucceedingTransactionSync),
        ("testFailingTransactionSync", testFailingTransactionSync),
        ("testCancellingTransaction", testCancellingTransaction),
        ("testTransactionResultsInBookmark", testTransactionResultsInBookmark),
        ("testGettingStartedExample", testGettingStartedExample),
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
