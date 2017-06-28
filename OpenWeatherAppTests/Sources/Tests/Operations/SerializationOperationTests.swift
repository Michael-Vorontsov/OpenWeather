//
//  SerializationOperationTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
@testable import OpenWeatherApp

private let consts = (
  successSingleJSON : "{\"id\": 0 }".data(using: String.Encoding.utf8)!,
  successCollectionJSON : "[{\"id\": 0},\n{\"id\": 1}]".data(using: String.Encoding.utf8)!,
  corruptedJSON : "{\"id\" : 0".data(using: String.Encoding.utf8)!,
  timeout : 120.0
)

class SerializationOperationTests: XCTestCase {
  
  var queue: OperationQueue!
  var buffer: NSData!
  var collection: NSMutableArray!
  
  override func setUp() {
    super.setUp()
    queue = OperationQueue()
    collection = NSMutableArray()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testSingleJSONSerialization() {
    
    // Prepare
    buffer = consts.successSingleJSON as NSData
    
    let operationToTest = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: collection
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
    XCTAssertEqual(collection.count, 1)
  }
  
  
  func testCancledDependantOperation() {
    
    // Prepare
    buffer = consts.successSingleJSON as NSData
    
    let operationToTest = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: collection
    )
    let operationToCancel = Operation()
    operationToTest.addDependency(operationToCancel)
    operationToCancel.cancel()

    //Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    queue.addOperation(operationToCancel)
    wait(for: [exp], timeout: consts.timeout)
    
    //Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertNil(operationToTest.error)
    XCTAssertEqual(collection.count, 0)
  }
  
  func testOperationCancellation() {
    
    // Prepare
    buffer = consts.successSingleJSON as NSData
    
    let operationToTest = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: collection
    )
    
    //Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    operationToTest.cancel()
    wait(for: [exp], timeout: consts.timeout)
    
    //Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertNil(operationToTest.error)
    XCTAssertEqual(collection.count, 0)
  }
  
  func testCollectionJSONSerialization() {
    
    // Prepare
    buffer = consts.successCollectionJSON as NSData
    
    let operationToTest = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: collection
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
    XCTAssertEqual(collection.count, 2)
  }

  func testCorruptedJSONSerialization() {
    
    // Prepare
    buffer = consts.corruptedJSON as NSData
    
    let operationToTest = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: collection
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
    XCTAssertEqual(collection.count, 0)
  }

}
