//
//  ParseOperationTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest

@testable import OpenWeatherApp

private let consts = (
  successSingleCollection : [["id" : 0]],
  timeout : 120.0
)

private struct SampleStruct {
  let id: Int
}

class ParseOperationTests: XCTestCase {
    
  var queue: OperationQueue!
  var infoCollection: NSArray!
  var resultCollection: NSMutableArray!
  
  override func setUp() {
    super.setUp()
    queue = OperationQueue()
    resultCollection = NSMutableArray()
  }
  
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSuccessParsing() {
      
      // Prepare
      infoCollection = consts.successSingleCollection as NSArray
      
      let blockMapper = BlockMapper { info in
        return SampleStruct(id: info["id"] as? Int ?? -1)
      }
  
      let operationToTest = ParseOperation(
        serializedCollection: infoCollection,
        resultCollection: resultCollection,
        mapper: blockMapper
      )
      
      //Execute
      let exp = self.expectation(description: "operation completed!")
      operationToTest.completionBlock = { exp.fulfill() }
      queue.addOperation(operationToTest)
      wait(for: [exp], timeout: consts.timeout)
      
      
      //Check
      XCTAssertTrue(operationToTest.isFinished)
      XCTAssertFalse(operationToTest.isCancelled)
      XCTAssertNil(operationToTest.error)
      XCTAssertEqual(operationToTest.results.count, 1)
      XCTAssertEqual(resultCollection.count, 1)
    }
  
  func testMarshalErrorParsing() {
    
    // Prepare
    infoCollection = consts.successSingleCollection as NSArray
    
    let blockMapper = BlockMapper { info in
      throw OperationError.missingData
    }
    
    let operationToTest = ParseOperation(
      serializedCollection: infoCollection,
      resultCollection: resultCollection,
      mapper: blockMapper
    )
    
    //Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    wait(for: [exp], timeout: consts.timeout)
    
    
    //Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertNotNil(operationToTest.error)
    XCTAssertEqual(operationToTest.results.count, 0)
    XCTAssertEqual(resultCollection.count, 0)
  }

  func testCancledDependantOperation() {
    // Prepare
    infoCollection = consts.successSingleCollection as NSArray
    
    let blockMapper = BlockMapper { info in
      return SampleStruct(id: info["id"] as? Int ?? -1)
    }
    
    let operationToTest = ParseOperation(
      serializedCollection: infoCollection,
      resultCollection: resultCollection,
      mapper: blockMapper
    )
    
    let operationToCancel = Operation()
    operationToTest.addDependency(operationToCancel)
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    operationToCancel.cancel()
    queue.addOperation(operationToTest)
    queue.addOperation(operationToCancel)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertNil(operationToTest.error)
    XCTAssertEqual(operationToTest.results.count, 0)
    XCTAssertEqual(resultCollection.count, 0)
  }
 
}
