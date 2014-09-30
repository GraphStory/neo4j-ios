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
let TheoNodeID: String                  = "100"
let TheoNodeIDForRelationship: String   = "101"
let TheoNodePropertyName: String        = "title"

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
    
    func test_001_successfullyFetchNode() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_002_successfullyFetchNode")
        
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            XCTAssert(node? != nil, "Node data can't be nil")
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            println("meta in success \(node!.meta) node \(node) error \(error)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_002_successfullyAccessProperty() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_003_successfullyAccessProperty")
        
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            println("meta in success \(node!.meta) [node \(node)] error \(error)")
            
            XCTAssert(node!.meta != nil, "Meta data can't be nil")
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description)")
            
            let nodeObject: Node = node!
            let nodePropertyValue: AnyObject? = nodeObject.getProp(TheoNodePropertyName)
            
            XCTAssert(nodePropertyValue != nil, "The nodeProperty can't be nil")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_003_successfullyHandleNonExistantAccessProperty() {
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_004_successfullyHandleNonExistantAccessProperty")
        let randomString: String = NSUUID.UUID().UUIDString
        
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            println("meta in success \(node!.meta) node \(node) error \(error)")
            
            XCTAssert(node!.meta != nil, "Meta data can't be nil")
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
    
    func test_004_successfullyAddNodeWithOutLabels() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_005_successfullyAddNodeWithOutLabels")
        let node = Node()
        let randomString: String = NSUUID.UUID().UUIDString

        node.setProp("unitTestKey_1", propertyValue: "unitTestValue_1" + randomString)
        node.setProp("unitTestKey_2", propertyValue: "unitTestValue_2" + randomString)
        
        theo.saveNode(node, completionBlock: {(node, error) in
        
            println("new node \(node)")
            
            XCTAssert(node!.meta != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            exp.fulfill()
        });
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_005_successfullyAddRelationship() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_006_successfullyAddRelationship")
        
        /**
         * Setup dispatch group since you to make a 2 part transation
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
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            println("meta in success \(node!.meta) node \(node) error \(error)")
            
            XCTAssert(node!.meta != nil, "Meta data can't be nil")
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
        theo.fetchNode(TheoNodeIDForRelationship, completionBlock: {(node, error) in
            
            println("meta in success \(node!.meta) node \(node) error \(error)")
            
            XCTAssert(node!.meta != nil, "Meta data can't be nil")
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

        dispatch_group_notify(fetchDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

            XCTAssertNotNil(parentNode, "parent node can't be nil")
            XCTAssertNotNil(relatedNode, "relatedNode node can't be nil")
            
            relationship.relate(parentNode!, toNode: relatedNode!, type: RelationshipType.KNOWS)
            relationship.setProp("my_relationship_property_name", propertyValue: "my_relationship_property_value")

            theo.saveRelationship(relationship, completionBlock: {(node, error) in
            
                XCTAssert(node!.meta != nil, "Meta data can't be nil")
                XCTAssert(node != nil, "Node data can't be nil")
                XCTAssert(error == nil, "Error must be nil \(error?.description)")
                
                exp.fulfill()
            })
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_006_succesfullyUpdateNodeWithProperties() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_008_succesfullyUpdateNodeWithProperties")
        
       /**
        * Setup dispatch group since you to make a 2 part transation
        */
        
        let nodeFetchQueueName: String           = "com.theo.node.fetch.queue"
        let fetchDispatchGroup: dispatch_group_t = dispatch_group_create()
        
        var updateNode: Node?
       
       /**
        * Fetch the parent node
        */
        
        dispatch_group_enter(fetchDispatchGroup)
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            println("test_008_succesfullyUpdateNodeWithProperties \(node!.meta) node \(node) error \(error)")

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {

                updateNode = nodeObject
                
                XCTAssert(node!.meta != nil, "Meta data can't be nil")
            }
            
            dispatch_group_leave(fetchDispatchGroup)
        })
        
       /**
        * End it
        */
        
        dispatch_group_notify(fetchDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            XCTAssertNotNil(updateNode, "updateNode node can't be nil")
            
            let updatedPropertiesDictionary: [String:String] = ["test_update_property_label_1": "test_update_property_lable_2"]
            
            theo.updateNode(updateNode!, properties: updatedPropertiesDictionary,
                completionBlock: {(node, error) in
            
                    XCTAssert(error == nil, "Error must be nil \(error?.description)")
                    
                    exp.fulfill()
            })
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_007_successfullyDeleteRelationship() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_009_successfullyDeleteRelationship")

        let fetchDispatchGroup: dispatch_group_t = dispatch_group_create()

        var relationshipIDToDelete: String?
        var nodeIDWithRelationships: String?
        
        /**
         * Fetch relationship for main RUD node
         */
        
        dispatch_group_enter(fetchDispatchGroup)
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            println("test_009_successfullyDeleteRelationship \(node!.meta) node \(node) error \(error)")
            
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                
                XCTAssert(node!.meta != nil, "Meta data can't be nil")
                
                nodeIDWithRelationships = nodeObject.meta!.nodeID()
                
                XCTAssertNotNil(nodeIDWithRelationships, "nodeIDWithRelationships for relationships deletion can't be nil");
            }
            
            dispatch_group_leave(fetchDispatchGroup)
        })

        
        /**
         * Delete the relationship
         */

        dispatch_group_notify(fetchDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            theo.fetchRelationshipsForNode(nodeIDWithRelationships!, direction: RelationshipDirection.ALL, types: nil, completionBlock: {(relationships, error) in
                
                XCTAssert(relationships.count >= 1, "Relationships must be exist")
                XCTAssertNil(error, "Error should be nil \(error)")
                
                if let foundRelationship: Relationship = relationships[0] as Relationship! {
                    
                    if let relMeta: RelationshipMeta = foundRelationship.relationshipMeta {
                        relationshipIDToDelete = relMeta.relationshipID()
                    }

                    XCTAssertNotNil(relationshipIDToDelete, "relationshipIDToDelete can't be nil")
                    
                    theo.deleteRelationship(relationshipIDToDelete!, completionBlock: {error in
                        
                        XCTAssertNil(error, "Error should be nil \(error)")
                        
                        exp.fulfill()
                    })
                }
            })
        })

        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_008_succesfullyAddNodeWithLabel() {
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_005_successfullyAddNodeWithOutLabels")
        let node = Node()
        let randomString: String = NSUUID.UUID().UUIDString
        
        node.setProp("succesfullyAddNodeWithLabel_1", propertyValue: "succesfullyAddNodeWithLabel_1" + randomString)
        node.setProp("succesfullyAddNodeWithLabel_2", propertyValue: "succesfullyAddNodeWithLabel_2" + randomString)
        node.addLabel("test_010_succesfullyAddNodeWithLabel_" + randomString)

        theo.saveNode(node, labels: node.labels, completionBlock: {(_, error) in
            
            XCTAssertNil(error, "Error must be nil \(error?.description)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_009_successfullyDeleteExistingNode() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_010_successfullyDeleteExistingNode")

        var nodeIDForDeletion: String?
        let node = Node()
        let randomString: String = NSUUID.UUID().UUIDString
        
        let fetchDispatchGroup: dispatch_group_t = dispatch_group_create()
        
        dispatch_group_enter(fetchDispatchGroup)

        node.setProp("test_010_successfullyDeleteExistingNode_1", propertyValue: "test_010_successfullyDeleteExistingNode_1" + randomString)
        node.setProp("test_010_successfullyDeleteExistingNode_2", propertyValue: "test_010_successfullyDeleteExistingNode_2" + randomString)

        theo.saveNode(node, completionBlock: {(savedNode, error) in

            XCTAssertNil(error, "Error must be nil \(error?.description)")
            XCTAssertNotNil(savedNode, "Saved node can't be nil")

            nodeIDForDeletion = savedNode!.meta?.nodeID()
            
            dispatch_group_leave(fetchDispatchGroup)
        })
        
        dispatch_group_notify(fetchDispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            XCTAssertNotNil(nodeIDForDeletion, "nodeIDForDeletion must NOT be nil")
            
            theo.deleteNode(nodeIDForDeletion!, completionBlock: {error in
                
                XCTAssertNil(error, "Error should be nil \(error)")
                
                exp.fulfill()
            })
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_010_successfullyCommitTransaction() {

        let createStatement: String = "CREATE ( bike:Bike { weight: 10 } ) CREATE ( frontWheel:Wheel { spokes: 3 } ) CREATE ( backWheel:Wheel { spokes: 32 } ) CREATE p1 = bike -[:HAS { position: 1 } ]-> frontWheel CREATE p2 = bike -[:HAS { position: 2 } ]-> backWheel RETURN bike, p1, p2"        
        let resultDataContents: Array<String> = ["row", "graph"]
        let statement: Dictionary <String, AnyObject> = ["statement" : createStatement, "resultDataContents" : resultDataContents]
        let statements: Array<Dictionary <String, AnyObject>> = [statement]
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectationWithDescription("test_010_successfullyCommitTransaction")
        
        theo.executeTransaction(statements, completionBlock: {(response, error) in
        
            XCTAssertNil(error, "Error must be nil \(error?.description)")
            XCTAssertFalse(response.keys.isEmpty, "Response dictionary must not be empty \(response)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
}
