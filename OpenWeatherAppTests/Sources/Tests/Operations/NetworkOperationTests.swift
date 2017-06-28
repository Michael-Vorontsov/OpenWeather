//
//  NetworkOperationTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
@testable import OpenWeatherApp

private let consts = (
  successMockPath : "https://jsonplaceholder.typicode.com/users",
  connectionErrorMockPath : "just://wrong_url",
  webErrorMockPath : "https://google.com/non-existed-page",
  timeout : 120.0
)

class NetworkOperationTests: XCTestCase {
  
  var queue: OperationQueue!
  var request: URLRequest!
  var buffer: NSMutableData!
  
  override func setUp() {
    super.setUp()
    queue = OperationQueue()
    buffer = NSMutableData()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testSuccessOperation() {
    // Prepare
    request = URLRequest(url: URL(string: consts.successMockPath)!)

    let operationToTest = NetworkOperation(
      request: request as NSURLRequest,
      buffer: buffer
    )
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertFalse(operationToTest.isCancelled)
    XCTAssertTrue(buffer.length > 0)
  }
  
  func testConnectionErrorOperation() {
    // Prepare
    request = URLRequest(url: URL(string: consts.connectionErrorMockPath)!)
    
    let operationToTest = NetworkOperation(
      request: request as NSURLRequest,
      buffer: buffer
    )
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertFalse(buffer.length > 0)
  }

  func testWebErrorOperation() {
    // Prepare
    request = URLRequest(url: URL(string: consts.webErrorMockPath)!)
    
    let operationToTest = NetworkOperation(
      request: request as NSURLRequest,
      buffer: buffer
    )
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertTrue(buffer.length > 0)
  }

  
  func testOperationCancellation() {
    // Prepare
    request = URLRequest(url: URL(string: consts.successMockPath)!)
    
    let operationToTest = NetworkOperation(
      request: request as NSURLRequest,
      buffer: buffer
    )
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    operationToTest.cancel()
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertFalse(buffer.length > 0)
  }
  
  func testCancledDependantOperation() {
    // Prepare
    request = URLRequest(url: URL(string: consts.successMockPath)!)
    
    let operationToCancel = Operation()
    operationToCancel.cancel()
    
    let operationToTest = NetworkOperation(
      request: request as NSURLRequest,
      buffer: buffer
    )
    operationToTest.addDependency(operationToCancel)
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    queue.addOperation(operationToCancel)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertTrue(operationToTest.isCancelled)
    XCTAssertEqual(buffer.length, 0)
  }
  
  func testOperationWithCachedData() {
    // Prepare
    buffer.append("Some data".data(using: .utf8)!)
    let dataLength = buffer.length
    request = URLRequest(url: URL(string: consts.successMockPath)!)
    
    let operationToTest = NetworkOperation(
      request: request as NSURLRequest,
      buffer: buffer
    )
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertFalse(operationToTest.isCancelled)
    XCTAssertTrue(buffer.length > 0)
    XCTAssertEqual(dataLength, buffer.length)
  }
  
}
