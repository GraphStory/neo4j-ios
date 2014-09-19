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

class Theo_000_RequestTestsTests: XCTestCase {
  
    let baseURL: String = "https://graph-1095-neosl01-7665.sl-stories.graphstory.com"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
  
    func test_000_successfullyFetchDBMeta() {

        let theo: Client = Client(baseURL: self.baseURL, user: "graph-1095", pass: "sqS7FrpojNHjJZcJBWtu")
        let exp = self.expectationWithDescription("test_000_successfullyFetchDBMeta")
        theo.metaDescription({(meta, error) in
          
          println("meta in success \(meta) error \(error)")
          
          XCTAssert(meta != nil, "Meta can't be nil")
          XCTAssert(error == nil, "Error must be nil \(error?.description)")
          
          exp.fulfill()
        })

        self.waitForExpectationsWithTimeout(10, handler: {error in
          XCTAssertNil(error, "\(error)")
        })
    }
  
    func test_001_denyAnonymousFetchDBMeta() {

        let theo: Client = Client(baseURL: self.baseURL, user: "", pass: "")
        let exp = self.expectationWithDescription("test_001_denyAnonymousFetchDBMeta")

        theo.metaDescription({(meta, error) in
          
            println("meta in deny \(meta) error \(error)")

            XCTAssert(meta == nil, "Meta must be nil")
            XCTAssert(error != nil, "Error must not be nil \(error?.description)")

            exp.fulfill()
        })

        self.waitForExpectationsWithTimeout(10){ error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func test_002_successfullyFetchNode() {
    
        let theo: Client = Client(baseURL: self.baseURL, user: "graph-1095", pass: "sqS7FrpojNHjJZcJBWtu")
        let exp = self.expectationWithDescription("test_002_successfullyFetchNode")
        
        theo.fetchNode(100, completionBlock: {(metaData, node, error) in

            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_003_successfullyAccessProperty() {
    
        let theo: Client = Client(baseURL: self.baseURL, user: "graph-1095", pass: "sqS7FrpojNHjJZcJBWtu")
        let exp = self.expectationWithDescription("test_003_successfullyAccessProperty")
        
        theo.fetchNode(100, completionBlock: {(metaData, node, error) in
            
            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            let nodeObject: Node = node!
            let nodePropertyValue: AnyObject? = nodeObject.getProp("name")
            
            XCTAssert(nodePropertyValue != nil, "The nodeProperty can't be nil")
            
            println("nodePropertyValue \(nodePropertyValue!)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
    
    func test_004_successfullyHandleNonExistantAccessProperty() {
        
        let theo: Client = Client(baseURL: self.baseURL, user: "graph-1095", pass: "sqS7FrpojNHjJZcJBWtu")
        let exp = self.expectationWithDescription("test_003_successfullyAccessProperty")
        let randomString: String = NSUUID.UUID().UUIDString
        
        theo.fetchNode(100, completionBlock: {(metaData, node, error) in
            
            println("meta in success \(metaData) node \(node) error \(error)")
            
            XCTAssert(metaData != nil, "Meta data can't be nil")
            XCTAssert(node != nil, "Node data can't be nil")
            XCTAssert(error == nil, "Error must be nil \(error?.description)")
            
            let nodeObject: Node = node!
            let nodePropertyValue: AnyObject? = nodeObject.getProp(randomString)

            XCTAssertNil(nodePropertyValue, "The nodeProperty must be nil")
            
            println("nodePropertyValue \(nodePropertyValue)")
            
            exp.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10, handler: {error in
            XCTAssertNil(error, "\(error)")
        })
    }
}
