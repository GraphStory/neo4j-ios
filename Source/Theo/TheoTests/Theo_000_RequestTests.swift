//
//  TheoTests.swift
//  TheoTests
//
//  Created by Cory D. Wiles on 9/15/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import UIKit
import Foundation
import XCTest

let TheoTimeoutInterval: NSTimeInterval = 10
let TheoNodeIDForRUD: String = "100"
let TheoNodeIDForRelationship: String = "101"

class ConfigLoader: NSObject {
    
    class func loadConfig() -> Config {
        
        let filePath: String = NSBundle(forClass: ConfigLoader.classForKeyedArchiver()).pathForResource("TheoConfig", ofType: "json")!
        
        return Config(pathToFile: filePath)
    }
}

class Theo_000_RequestTestsTests: XCTestCase {
  
    let configuration: Config = ConfigLoader.loadConfig()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
  
    func test_000_successfullyFetchDBMeta() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_000_successfullyFetchDBMeta")
        theo.metaDescription({(meta, error) in
          
          println("meta in success \(meta) error \(error)")
          
          XCTAssert(meta != nil, "Meta can't be nil")
          XCTAssert(error == nil, "Error must be nil \(error?.description)")
          
          exp.fulfill()
        })

        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
          XCTAssertNil(error, "\(error)")
        })
    }
  
    func test_001_denyAnonymousFetchDBMeta() {

        let theo: Client = Client(baseURL: configuration.host, user: "", pass: "")
        let exp = self.expectationWithDescription("test_001_denyAnonymousFetchDBMeta")

        theo.metaDescription({(meta, error) in
          
            println("meta in deny \(meta) error \(error)")

            XCTAssert(meta == nil, "Meta must be nil")
            XCTAssert(error != nil, "Error must not be nil \(error?.description)")

            exp.fulfill()
        })

        self.waitForExpectationsWithTimeout(TheoTimeoutInterval){ error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func test_002_successfullyFetchNode() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_002_successfullyFetchNode")
        
        theo.fetchNode(TheoNodeIDForRUD, completionBlock: {(metaData, node, error) in

            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_003_successfullyAccessProperty() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_003_successfullyAccessProperty")
        
        theo.fetchNode(TheoNodeIDForRUD, completionBlock: {(metaData, node, error) in
            
            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            let nodeObject: Node = node!
            let nodePropertyValue: AnyObject? = nodeObject.getProp("title")
            
            XCTAssert(nodePropertyValue != nil, "The nodeProperty can't be nil")
            
            println("nodePropertyValue \(nodePropertyValue!)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_004_successfullyHandleNonExistantAccessProperty() {
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_004_successfullyHandleNonExistantAccessProperty")
        let randomString: String = NSUUID.UUID().UUIDString
        
        theo.fetchNode(TheoNodeIDForRUD, completionBlock: {(metaData, node, error) in
            
            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            let nodeObject: Node = node!
            let nodePropertyValue: AnyObject? = nodeObject.getProp(randomString)

            XCTAssertNil(nodePropertyValue, "The nodeProperty must be nil")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_005_successfullyAddNodeWithOutLabels() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_005_successfullyAddNodeWithOutLabels")
        let node = Node()
        let randomString: String = NSUUID.UUID().UUIDString

        node.setProp("unitTestKey_1", propertyValue: "unitTestValue_1" + randomString)
        node.setProp("unitTestKey_2", propertyValue: "unitTestValue_2" + randomString)
        
        theo.saveNode(node, completionBlock: {(metaData, node, error) in
        
            println("new node \(node)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            exp.fulfill()
        });
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_006_successfullyAddRelationship() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_006_successfullyAddRelationship")
        
        /**
         * Setup dispatch group since you to make a 3 part transation
         */

        let nodeFetchQueueName: String           = "com.theo.node.fetch.queue"
        let fetchDispatchGroup: dispatch_group_t = dispatch_group_create()
        
        var parentNode: Node?
        var relatedNode: Node?
        var relationship: Relationship = Relationship()
        
        /**
         * Fetch the parent node
         */
        
        dispatch_group_enter(fetchDispatchGroup)
        theo.fetchNode(TheoNodeIDForRUD, completionBlock: {(metaData, node, error) in
            
            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                parentNode = nodeObject
            }
            
            dispatch_group_leave(fetchDispatchGroup)
        })
        
        /**
         * Fetch the related node
         */

        dispatch_group_enter(fetchDispatchGroup)
        theo.fetchNode(TheoNodeIDForRelationship, completionBlock: {(metaData, node, error) in
            
            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
          
            if let nodeObject: Node = node {
                relatedNode = nodeObject
            }
            
            dispatch_group_leave(fetchDispatchGroup)
        })
        
        /**
         * End it
         */

        dispatch_group_notify(fetchDispatchGroup, dispatch_get_main_queue(), {
            
            XCTAssertNotNil(parentNode, "parent node can't be nil")
            XCTAssertNotNil(relatedNode, "relatedNode node can't be nil")
            
            relationship.relate(parentNode!, toNode: relatedNode!, type: RelationshipType.KNOWS)
            theo.saveRelationship(relationship, completionBlock: {(metaData, node, error) in
            
                XCTAssert(metaData != nil, "Meta data can't be nil")
                XCTAssert(node != nil, "Node data can't be nil")
                XCTAssert(error == nil, "Error must be nil \(error?.description)")
                
                exp.fulfill()
            })
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_007_successfullyDeleteExistingNode() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_007_successfullyDeleteExistingNode")
        
        theo.deleteNode(TheoNodeIDForRUD, completionBlock: {error in
            
            XCTAssertNil(error, "Error should be nil \(error)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
}
