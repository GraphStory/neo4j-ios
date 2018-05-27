import Foundation
import XCTest
import PackStream
import Socket
import Result
import Bolt
import LoremSwiftum

@testable import Theo

class Theo_001_LotsOfDataScenario: XCTestCase {
    
    let label = Lorem.word
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    
    func testScenario() throws {
        let builder = Theo_000_BoltClientTests()
        let client = try builder.makeClient()
        
        print("Test with '\(label)'")
        
        measure {
            do {
                try client.executeAsTransaction { tx in
                    try self.buildData(client: client)
                    try self.findData(client: client)
                    tx.markAsFailed()
                }
            } catch {
                XCTFail("Hmm....")
            }
        }
    }

    let data: [String] = Lorem.sentences(count: 30).split(".")
    private var pos = 0
    private var sentence: String {
        pos = pos + 1
        return data[pos % data.count]
    }
    
    private var word: String {
        pos = pos + 1
        let words = self.sentence.split(" ")
        return words[pos % words.count]
    }
    
    func buildData(client: BoltClient) throws {
        
        var nodes = [Node]()
        
        let cypherCreateResult = client.executeCypherSync("CREATE (n:\(label) {created_at: TIMESTAMP()}) RETURN n")
        XCTAssertTrue(cypherCreateResult.isSuccess)
        XCTAssertEqual(1, cypherCreateResult.value!.nodes.count)
        let nodeWithTimestamp = cypherCreateResult.value!.nodes.values.first!
        let timestamp: TimeInterval = Double(nodeWithTimestamp["created_at"] as? Int64 ?? 0) / 1000.0
        let diff = Date().timeIntervalSince1970 - timestamp
        XCTAssertLessThan(diff, 60.0)
        
        let emptyParameterResult = client.executeCypherSync("CREATE (n:\(label) {param: \"\"}) RETURN n")
        XCTAssertTrue(emptyParameterResult.isSuccess)
        XCTAssertEqual(1, emptyParameterResult.value!.nodes.count)
        let nodeWithEmptyParameter = emptyParameterResult.value!.nodes.values.first!
        let param = nodeWithEmptyParameter["param"] as? String
        XCTAssertEqual(param, "")

        for _ in 0..<100 {
            let node = Node()
            node.add(label: label)
            for _ in 0..<15 {
                let key = self.word
                let value = self.sentence
                node[key] = value
            }
            nodes.append(node)
        }
        let result = client.createNodesSync(nodes: nodes)
        client.pullSynchronouslyAndIgnore()
        XCTAssertTrue(result.isSuccess)
    }
    
    func findData(client: BoltClient) throws {
        client.nodesWith(label: label, limit: 0) { result in
            switch result {
            case .failure(let error):
                XCTFail("Failure during query: \(error.localizedDescription)")
            case .success(let nodes):
                XCTAssertEqual(nodes.count, 102)
                let deleteResult = client.deleteNodesSync(nodes: nodes)
                XCTAssertTrue(deleteResult.isSuccess)
                client.pullSynchronouslyAndIgnore()
            }
        }
    }
}
