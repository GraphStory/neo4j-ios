import Foundation
import XCTest
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
        
        try client.executeAsTransaction() { (tx, completionBlock) in
            try client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})")
            try client.executeCypher("MATCH (n:TheoTestNode { foo: \"bar\"}) RETURN n")
            try client.executeCypher("MATCH (n:TheoTestNode { foo: \"bar\"}) DETACH DELETE n")
            try completionBlock()
            exp.fulfill()
        }
        
        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error, "\(error ?? "Error undefined")")
        })
    }
    
    func testFailingTransaction() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testFailingTransaction")

        try client.executeAsTransaction() { (tx, completionBlock) in
            do {
                try client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})")
                try client.executeCypher("MATCH (n:TheoTestNode { foo: \"bar\"}) RETURN n")
                try client.executeCypher("MAXXXTCH (n:TheoTestNode { foo: \"bar\"}) DETACH DELETE n")
            } catch {
                tx.markAsFailed()
            }

            try completionBlock()
            
            XCTAssertFalse(tx.succeed)
            exp.fulfill()
        }
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error, "\(error ?? "Error undefined")")
        })
    }
    
    func testCancellingTransaction() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testCancellingTransaction")
        
        try client.executeAsTransaction() { (tx, completionBlock) in
            tx.markAsFailed()
            try completionBlock()
            exp.fulfill()
        }
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: { error in
            XCTAssertNil(error, "\(error ?? "Error undefined")")
        })

    }
    
    func testTransactionResultsInBookmark() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testTransactionResultsInBookmark")
        
        try client.executeAsTransaction() { (tx, completionBlock) in
            try client.executeCypher("CREATE (n:TheoTestNode { foo: \"bar\"})")
            try completionBlock()
            
            if let bookmark = client.getBookmark() {
                XCTAssertNotEqual("", bookmark)
            } else {
                XCTFail("Bookmark should not be nil")
            }
            exp.fulfill()
        }
        
        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error, "\(error ?? "Error undefined")")
        })
    }
    
    func testGettingStartedExample() throws {
        let client = try makeClient()
        let exp = self.expectation(description: "testGettingStartedExample")
        
        try client.executeAsTransaction() { (tx, completionBlock) in
            try client.executeCypher("CREATE (a:Person {name: {name}, title: {title}})",
                                     params: ["name": "Arthur", "title": "King"])
            try completionBlock()
            
            try client.executeCypher("MATCH (a:Person) WHERE a.name = {name} " +
            "RETURN a.name AS name, a.title AS title", params: ["name": "Arthur"]) { success in
                
                exp.fulfill()
            }
            
        }
        
        self.waitForExpectations(timeout: 10, handler: { error in
            XCTAssertNil(error, "\(error ?? "Error undefined")")
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
