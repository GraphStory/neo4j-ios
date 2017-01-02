//
//  TheoTests.swift
//  TheoTests
//
//  Created by Cory D. Wiles on 9/15/14.
//  Copyright (c) 2014 Theo. All rights reserved.
//

import Foundation
import XCTest

let TheoTimeoutInterval: TimeInterval = 10
let TheoNodeID: String                  = "100"
let TheoNodeIDForRelationship: String   = "101"
let TheoNodePropertyName: String        = "title"

class ConfigLoader: NSObject {
    
    class func loadConfig() -> Config {
        
        let filePath: String = Bundle(for: ConfigLoader.classForKeyedArchiver()!).path(forResource: "TheoConfig", ofType: "json")!
        
        return Config(pathToFile: filePath)
    }
}

class Theo_000_RequestTests: XCTestCase {
  
    let configuration: Config = ConfigLoader.loadConfig()

    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
    }

    override func tearDown() {
        super.tearDown()
    }
  
    func test_000_successfullyFetchDBMeta() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_000_successfullyFetchDBMeta")
        
        theo.metaDescription({(meta, error) in
          
          print("meta in success \(meta) error \(error)")
          
          XCTAssert(meta != nil, "Meta can't be nil")
          XCTAssert(error == nil, "Error must be nil \(error?.description)")
          
          exp.fulfill()
        })

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
          XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_001_successfullyFetchNode() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_002_successfullyFetchNode")
        
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            print("meta in success \(node?.meta) node \(node) error \(error)")
            
            exp.fulfill()
        })
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_002_successfullyAccessProperty() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_002_successfullyAccessProperty")
        
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            print("meta in success \(node?.meta) [node \(node)] error \(error)")
            
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                let nodePropertyValue: AnyObject? = nodeObject.getProp(TheoNodePropertyName)
                
                XCTAssert(nodePropertyValue != nil, "The nodeProperty can't be nil")
                
                exp.fulfill()
            }
        })
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_003_successfullyHandleNonExistantAccessProperty() {
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_003_successfullyHandleNonExistantAccessProperty")
        let randomString: String = NSUUID().uuidString
        
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            print("meta in success \(node?.meta) node \(node) error \(error)")
            
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                let nodePropertyValue: AnyObject? = nodeObject.getProp(randomString)
                
                XCTAssertNil(nodePropertyValue, "The nodeProperty must be nil")
                
                exp.fulfill()
            }
        })
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_004_successfullyAddNodeWithOutLabels() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_004_successfullyAddNodeWithOutLabels")
        let node = Node()
        let randomString: String = NSUUID().uuidString

        node.setProp("unitTestKey_1", propertyValue: ("unitTestValue_1" + randomString) as AnyObject)
        node.setProp("unitTestKey_2", propertyValue: ("unitTestValue_2" + randomString) as AnyObject)
        
        theo.createNode(node, completionBlock: {(node, error) in
        
            print("new node \(node)")
            
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            exp.fulfill()
        });
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_005_successfullyAddRelationship() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_005_successfullyAddRelationship")
        
        /**
         * Setup dispatch group since you to make a 2 part transation
         */

        let fetchDispatchGroup: DispatchGroup = DispatchGroup()
        
        var parentNode: Node?
        var relatedNode: Node?
        let relationship: Relationship = Relationship()
        
        /**
         * Fetch the parent node
         */
        
        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            print("meta in success \(node?.meta) node \(node) error \(error)")
            
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                parentNode = nodeObject
            }
            
            fetchDispatchGroup.leave()
        })
        
        /**
         * Fetch the related node
         */

        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeIDForRelationship, completionBlock: {(node, error) in
            
            print("meta in success \(node?.meta) node \(node) error \(error)")
            
            XCTAssert(node?.meta != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
          
            if let nodeObject: Node = node {
                relatedNode = nodeObject
            }
            
            fetchDispatchGroup.leave()
        })
        
        /**
         * End it
         */
//http://stackoverflow.com/questions/38552180/dispatch-group-cannot-notify-to-main-thread
        fetchDispatchGroup.notify(queue: DispatchQueue.main) {

            XCTAssertNotNil(parentNode, "parent node can't be nil")
            XCTAssertNotNil(relatedNode, "relatedNode node can't be nil")
            
            guard let parentNode = parentNode,
                let relatedNode = relatedNode else {
                    XCTFail("These nodes must have been defined")
                    return
            }
            
            relationship.relate(parentNode, toNode: relatedNode, type: RelationshipType.KNOWS)
            relationship.setProp("my_relationship_property_name", propertyValue: "my_relationship_property_value")

            theo.createRelationship(relationship, completionBlock: {(rel, error) in
            
                XCTAssert(rel?.relationshipMeta != nil, "Meta data can't be nil")
                XCTAssert(rel != nil, "Node data can't be nil")
                XCTAssert(error == nil, "Error must be nil \(error?.description)")
                
                exp.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_006_succesfullyUpdateNodeWithProperties() {
    
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_006_succesfullyUpdateNodeWithProperties")
        
       /**
        * Setup dispatch group since you to make a 2 part transation
        */

        let fetchDispatchGroup: DispatchGroup = DispatchGroup()
        
        var updateNode: Node?
       
       /**
        * Fetch the parent node
        */
        
        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            print("test_008_succesfullyUpdateNodeWithProperties \(node?.meta) node \(node) error \(error)")

            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {

                updateNode = nodeObject
                
                XCTAssert(node?.meta != nil, "Meta data can't be nil")
            }
            
            fetchDispatchGroup.leave()
        })
        
       /**
        * End it
        */
        
        fetchDispatchGroup.notify(queue: DispatchQueue.main) {
            
            XCTAssertNotNil(updateNode, "updateNode node can't be nil")
            guard let updateNode = updateNode else {
                XCTFail("Node not defined, abort further testing")
                return
            }
            
            let updatedPropertiesDictionary: [String:AnyObject] = ["test_update_property_label_1": "test_update_property_lable_2" as AnyObject]
            
            theo.updateNode(updateNode, properties: updatedPropertiesDictionary,
                completionBlock: {(node, error) in
            
                    XCTAssert(error == nil, "Error must be nil \(error?.description)")
                    
                    exp.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_007_successfullyDeleteRelationship() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_007_successfullyDeleteRelationship")

        let fetchDispatchGroup = DispatchGroup()

        var relationshipIDToDelete: String?
        var nodeIDWithRelationships: String?
        
        /**
         * Fetch relationship for main RUD node
         */
        
        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            print("test_007_successfullyDeleteRelationship \(node?.meta) node \(node) error \(error)")
            
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                
                XCTAssert(node?.meta != nil, "Meta data can't be nil")
                
                nodeIDWithRelationships = nodeObject.meta!.nodeID()
                
                XCTAssertNotNil(nodeIDWithRelationships, "nodeIDWithRelationships for relationships deletion can't be nil");
            }
            
            fetchDispatchGroup.leave()
        })

        
        /**
         * Delete the relationship
         */

        fetchDispatchGroup.notify(queue: DispatchQueue.main) {
            
            guard let nodeIDWithRelationships = nodeIDWithRelationships else {
                XCTFail("Abort, nodeIDWithRelationships was nil")
                return
            }
            
            theo.fetchRelationshipsForNode(nodeIDWithRelationships, direction: RelationshipDirection.ALL, types: nil, completionBlock: {(relationships, error) in
                
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
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_008_succesfullyAddNodeWithLabels() {
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_008_succesfullyAddNodeWithLabel")
        let node = Node()
        let randomString: String = NSUUID().uuidString
        
        node.setProp("succesfullyAddNodeWithLabel_1", propertyValue: "succesfullyAddNodeWithLabel_1" + randomString)
        node.setProp("succesfullyAddNodeWithLabel_2", propertyValue: "succesfullyAddNodeWithLabel_2" + randomString)
        node.setProp("succesfullyAddNodeWithLabel_3", propertyValue: 123456 as AnyObject)
        node.addLabel("test_008_succesfullyAddNodeWithLabel_" + randomString)

        theo.createNode(node, labels: node.labels, completionBlock: {(savedNode, error) in

            XCTAssertNil(error, "Error must be nil \(error?.description)")
            XCTAssertNotNil(savedNode, "Node can't be nil")
            guard let savedNode = savedNode else {
                XCTFail("Assert fell through, abort")
                return
            }
            XCTAssertFalse(savedNode.labels.isEmpty, "Labels must be set")

            exp.fulfill()
        })
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_009_successfullyCommitTransaction() {

        let createStatement: String = "CREATE ( bike:Bike { weight: 10 } ) CREATE ( frontWheel:Wheel { spokes: 3 } ) CREATE ( backWheel:Wheel { spokes: 32 } ) CREATE p1 = bike -[:HAS { position: 1 } ]-> frontWheel CREATE p2 = bike -[:HAS { position: 2 } ]-> backWheel RETURN bike, p1, p2"        
        let resultDataContents: Array<String> = ["REST"]
        let statement: Dictionary <String, AnyObject> = ["statement" : createStatement as AnyObject, "resultDataContents" : resultDataContents as AnyObject]
        let statements: Array<Dictionary <String, AnyObject>> = [statement]
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_010_successfullyCommitTransaction")
        
        theo.executeTransaction(statements, completionBlock: {(response, error) in
            
            XCTAssertNil(error, "Error must be nil \(error?.description)")
            XCTAssertFalse(response.keys.isEmpty, "Response dictionary must not be empty \(response)")
            
            exp.fulfill()
        })
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_011_succesfullyUpdateRelationshipWithProperties() {
        
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_011_succesfullyUpdateRelationshipWithProperties")
        
        let fetchDispatchGroup = DispatchGroup()
        
        var nodeIDWithRelationships: String?
        
        // Fetch relationship for main RUD node
        
        fetchDispatchGroup.enter()
        theo.fetchNode(TheoNodeID, completionBlock: {(node, error) in
            
            print("test_011_succesfullyUpdateRelationshipWithProperties \(node?.meta) node \(node) error \(error)")
            
            XCTAssertNotNil(node, "Node data can't be nil")
            XCTAssertNil(error, "Error must be nil \(error?.description)")
            
            if let nodeObject: Node = node {
                
                XCTAssert(node?.meta != nil, "Meta data can't be nil")
                
                nodeIDWithRelationships = nodeObject.meta!.nodeID()
                
                XCTAssertNotNil(nodeIDWithRelationships, "nodeIDWithRelationships for relationships deletion can't be nil");
            }
            
            fetchDispatchGroup.leave()
        })
        
        // Delete the relationship
        
        fetchDispatchGroup.notify(queue: DispatchQueue.main) {
            
            guard let nodeIDWithRelationships = nodeIDWithRelationships else {
                XCTFail("nodeIDWithRelationships not defined")
                return
            }
            theo.fetchRelationshipsForNode(nodeIDWithRelationships, direction: RelationshipDirection.ALL, types: nil, completionBlock: {(relationships, error) in
                
                XCTAssert(relationships.count >= 1, "Relationships must be exist")
                XCTAssertNil(error, "Error should be nil \(error)")
                
                if let foundRelationship: Relationship = relationships[0] as Relationship! {

                    let updatedProperties: Dictionary<String, AnyObject> = ["updatedRelationshipProperty" : "updatedRelationshipPropertyValue" as AnyObject]
                    
                    theo.updateRelationship(foundRelationship, properties: updatedProperties, completionBlock: {(_, error) in

                        XCTAssertNil(error, "Error should be nil \(error)")
                        
                        exp.fulfill()
                    })
                    
                } else {

                    XCTFail("no relationships where found")
                    
                    exp.fulfill()
                }
            })
        }
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_012_successfullyExecuteCyperRequest() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_012_successfullyExecuteCyperRequest")
        let cyperQuery: String = "MATCH (u:User {username: {user} }) WITH u MATCH (u)-[:FOLLOWS*0..1]->f WITH DISTINCT f,u MATCH f-[:LASTPOST]-lp-[:NEXTPOST*0..3]-p RETURN p.contentId as contentId, p.title as title, p.tagstr as tagstr, p.timestamp as timestamp, p.url as url, f.username as username, f=u as owner"
        let cyperParams: Dictionary<String, AnyObject> = ["user" : "ajordan" as AnyObject]

        theo.executeCypher(cyperQuery, params: cyperParams, completionBlock: {(cypher, error) in
            
            XCTAssertNil(error, "Error should be nil \(error)")
            XCTAssertNotNil(cypher, "Response can't be nil")
            
            exp.fulfill()
        })
        
        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_999_successfullyDeleteExistingNode() {

        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let exp = self.expectation(description: "test_999_successfullyDeleteExistingNode")

        var nodeIDForDeletion: String?
        let node = Node()
        let randomString: String = NSUUID().uuidString

        let createDispatchGroup = DispatchGroup()

        createDispatchGroup.enter()

        node.setProp("test_010_successfullyDeleteExistingNode_1", propertyValue: "test_010_successfullyDeleteExistingNode_1" + randomString)
        node.setProp("test_010_successfullyDeleteExistingNode_2", propertyValue: "test_010_successfullyDeleteExistingNode_2" + randomString)

        theo.createNode(node, completionBlock: {(savedNode, error) in

            XCTAssertNil(error, "Error must be nil \(error?.description)")
            XCTAssertNotNil(savedNode, "Saved node can't be nil")

            nodeIDForDeletion = savedNode?.meta?.nodeID()

            createDispatchGroup.leave()
        })

        createDispatchGroup.notify(queue: DispatchQueue.main) {

            XCTAssertNotNil(nodeIDForDeletion, "nodeIDForDeletion must NOT be nil")
            guard let nodeIDForDeletion = nodeIDForDeletion else {
                XCTFail("nodeIDForDeletion was not defined")
                return
            }

            theo.deleteNode(nodeIDForDeletion, completionBlock: {error in

                XCTAssertNil(error, "Error should be nil \(error)")

                exp.fulfill()
            })
        }

        self.waitForExpectations(timeout: TheoTimeoutInterval, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
}

extension Node {
    func setProp(_ propertyName: String, propertyValue: String) -> Void {
        
        let value: AnyObject = propertyValue as NSString
        self.setProp(propertyName, propertyValue: value)
    }
}

extension Relationship {
    func setProp(_ propertyName: String, propertyValue: String) -> Void {
        
        let value: AnyObject = propertyValue as NSString
        self.setProp(propertyName, propertyValue: value)
    }
}
