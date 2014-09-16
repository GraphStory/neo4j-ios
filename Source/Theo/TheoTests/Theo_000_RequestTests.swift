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
    
    let theo: Client = Client(baseURL: self.baseURL, user: "graph-1095", pass: "graph-1095")
    let exp: XCTestExpectation = self.expectationWithDescription("test success \(self.baseURL)")
    
    theo.metaDescription({(meta, error) in
      
      println("meta \(meta) error \(error)")
      
      XCTAssert(meta != nil, "Meta can't be nil")
      XCTAssert(error == nil, "Error must be nil \(error?.description)")
      
      exp.fulfill()
    })
    
    self.waitForExpectationsWithTimeout(TheoTimeoutInterval){ error in
      XCTAssertNil(error, "\(error)")
    }
  }
  
  func test_001_failToFetchDBMeta() {
    
    let theo: Client = Client(baseURL: self.baseURL)
    let exp: XCTestExpectation = self.expectationWithDescription("test fail \(self.baseURL)")
    
    theo.metaDescription({(meta, error) in
      
      println("meta \(meta) error \(error)")
      
      XCTAssert(meta == nil, "Meta must be nil")
      XCTAssert(error != nil, "Error must be nil \(error?.description)")
      
      exp.fulfill()
    })
    
    self.waitForExpectationsWithTimeout(TheoTimeoutInterval){ error in
      XCTAssertNil(error, "\(error)")
    }
  }
}
