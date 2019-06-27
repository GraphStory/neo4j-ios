import Foundation
import XCTest
import PackStream

import Result
import Bolt
//import LoremSwiftum

@testable import Theo

class TheoTestCase: XCTestCase {
    func makeClient() throws -> ClientProtocol {
        let client: BoltClient
        let configuration = Theo_000_BoltClientTests.configuration
        
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
                
                init(configuration: ClientConfigurationProtocol) {
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
    
    func performConnectSync(client: BoltClient, completionBlock: ((Bool) -> ())? = nil) {
        
        let result = client.connectSync()
        switch result {
        case let .failure(error):
            XCTFail("Failed connecting with error: \(error)")
            completionBlock?(false)
        case let .success(isSuccess):
            XCTAssertTrue(isSuccess)
            completionBlock?(true)
        }
    }
    
    func performConnect(client: BoltClient, completionBlock: ((Bool) -> ())? = nil) {
        client.connect() { connectionResult in
            switch connectionResult {
            case let .failure(error):
                XCTFail("Failed connecting with error: \(error)")
                completionBlock?(false)
            case let .success(isConnected):
                if !isConnected {
                    print("Error, could not connect!")
                }
                completionBlock?(isConnected)
            }
        }
    }
}

class Theo_001_LotsOfDataScenario: TheoTestCase {
    
    let label = Lorem.word
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    
    func testScenario() throws {
        let client = try makeClient()
        
        print("Test with '\(label)'")
        
        measure {
            do {
                //try client.executeAsTransaction(bookmark: nil) { tx in
                    try self.buildData(client: client)
                    try self.findData(client: client)
                    //tx.markAsFailed()
                //}
            } catch {
                XCTFail("Hmm....")
            }
        }
    }
    
    

    let data = Lorem.sentences(30).split(separator: ".")
    private var pos = 0
    private var sentence: String {
        pos = pos + 1
        return String(data[pos % data.count])
    }
    
    private var word: String {
        pos = pos + 1
        let words = self.sentence.split(separator: " ")
        return String(words[pos % words.count])
    }
    
    func buildData(client: ClientProtocol) throws {
        
        var nodes = [Node]()
        
        let cypherCreateResult = client.executeCypherSync("CREATE (n:\(label) {created_at: TIMESTAMP()}) RETURN n", params: [:])
        XCTAssertTrue(cypherCreateResult.isSuccess)
        XCTAssertEqual(1, cypherCreateResult.value!.nodes.count)
        let nodeWithTimestamp = cypherCreateResult.value!.nodes.values.first!
        let timestamp: TimeInterval = Double(nodeWithTimestamp["created_at"] as? Int64 ?? 0) / 1000.0
        let diff = Date().timeIntervalSince1970 - timestamp
        XCTAssertLessThan(diff, 60.0)
        
        let emptyParameterResult = client.executeCypherSync("CREATE (n:\(label) {param: \"\"}) RETURN n", params: [:])
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
    
    func findData(client: ClientProtocol) throws {
        client.nodesWith(label: label, andProperties: [:], skip: 0, limit: 0) { result in
            switch result {
            case .failure(let error):
                XCTFail("Failure during query: \(error.localizedDescription)")
            case .success(let nodes):
                XCTAssertEqual(nodes.count, 102)
                let deleteResult = client.deleteNodesSync(nodes: nodes)
                XCTAssertTrue(deleteResult.isSuccess)
                // client.pullSynchronouslyAndIgnore()
            }
        }
    }
}
