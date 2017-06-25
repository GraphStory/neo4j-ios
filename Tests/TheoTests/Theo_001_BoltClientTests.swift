import Foundation
import XCTest
import PackStream

@testable import Theo

#if os(Linux)
    import Dispatch
#endif

class Theo_001_BoltClientTests: XCTestCase {

    let configuration: BoltConfig = ConfigLoader.loadBoltConfig()


    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func makeClient() throws -> BoltClient {
        let client = try BoltClient(hostname: configuration.hostname,
                                    port: configuration.port,
                                    username: configuration.username,
                                    password: configuration.password,
                                    encrypted: configuration.encrypted)
        try client.connect()

        return client
    }

    func testSucceedingTransaction() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testSucceedingTransaction")

        try client.executeAsTransaction() { (tx) in
            var result = client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})")
            if case .failure(_) = result {
                XCTFail()
            }
            
            result = client.executeCypher("MATCH (n:TheoTestNode { foo: \"bar\"}) RETURN n")
            if case .failure(_) = result {
                XCTFail()
            }

            result = client.executeCypher("MATCH (n:TheoTestNode { foo: \"bar\"}) DETACH DELETE n")
            if case .failure(_) = result {
                XCTFail()
            }

            exp.fulfill()
        }

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testFailingTransaction() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testFailingTransaction")

        try client.executeAsTransaction() { (tx) in
            var result = client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})")
            if case .failure(_) = result {
                XCTFail()
            }
            
            result = client.executeCypher("MATCH (n:TheoTestNode { foo: \"bar\"}) RETURN n")
            if case .failure(_) = result {
                XCTFail()
            }
            
            result = client.executeCypher("MAXXXTCH (n:TheoTestNode { foo: \"bar\"}) DETACH DELETE n")
            if case .failure(_) = result {
                tx.markAsFailed()
            } else {
                XCTFail()
            }
            
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
            let result = client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})")
            if case .failure(_) = result {
                XCTFail()
            }

            exp.fulfill()
        }

        if let bookmark = client.getBookmark() {
            XCTAssertNotEqual("", bookmark)
            XCTAssertEqual("neo4j:bookmark:v1", bookmark.substring(to: bookmark.index(bookmark.startIndex, offsetBy: 17)))
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

        try client.executeCypher("MATCH (a:Person) WHERE a.name = {name} RETURN count(a) AS count", params: ["name": "Arthur"])  { success in

            XCTAssertTrue(success)

            try client.pullAll() { (success, response) in

                XCTAssertTrue(success)
                XCTAssertEqual(2, response.count)
                if let theResponse = response[0].items[0] as? List,
                   let n = Int(theResponse.items[0]) {
                    numberOfKingArthurs = n
                } else {
                    XCTFail("Response was not of the kind List")
                }

                figureOutNumberOfKingArthurs.leave()
            }
        }
        figureOutNumberOfKingArthurs.wait()
        XCTAssertNotEqual(-1, numberOfKingArthurs)

        // Now lets run the actual test

        try client.executeAsTransaction() { (tx) in
            let result = client.executeCypher("CREATE (a:Person {name: {name}, title: {title}})",
                                               params: ["name": "Arthur", "title": "King"])
            if case .failure(_) = result {
                XCTFail()
            }


            try client.executeCypher("MATCH (a:Person) WHERE a.name = {name} " +
            "RETURN a.name AS name, a.title AS title", params: ["name": "Arthur"])  { success in

                XCTAssertTrue(success)

                try client.pullAll() { (success, response) in

                    XCTAssertTrue(success)
                    XCTAssertEqual(numberOfKingArthurs + 2, response.count)

                    tx.markAsFailed() // This should undo the beginning CREATE even though we have pulled it here
                    exp.fulfill()
                }
            }
        }

        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error)
        })
    }

    static var allTests = [
        ("testSucceedingTransaction", testSucceedingTransaction),
        ("testFailingTransaction", testFailingTransaction),
        ("testCancellingTransaction", testCancellingTransaction),
        ("testTransactionResultsInBookmark", testTransactionResultsInBookmark),
        ("testGettingStartedExample", testGettingStartedExample),
    ]

}
