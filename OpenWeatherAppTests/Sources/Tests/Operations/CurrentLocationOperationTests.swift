//
//  CurrentLocationOperationTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
@testable import OpenWeatherApp

private let consts = (
  dataModelExt : "momd",
  timeout : 120.0
)

class CurrentLocationOperationTests: XCTestCase {
    
  var queue: OperationQueue!
  var collection: NSMutableArray!
  
  override func setUp() {
    super.setUp()
    queue = OperationQueue()
    collection = NSMutableArray()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  func testSuccessOperation() {
    
    // Prepare
    
    let operationToTest = CurrentLocationOperation( container: collection)
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
  
}
