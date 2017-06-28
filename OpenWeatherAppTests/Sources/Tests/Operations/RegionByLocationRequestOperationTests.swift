//
//  RegionByLocationRequestOperationTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import CoreLocation
@testable import OpenWeatherApp

private let consts = (
  location : CLLocation(latitude: 51.29, longitude: 0.0),
  path : "api.openweathermap.org/data/2.5",
  key : "some_key",
  expectedKey : "APPID=some_key",
  expectedPath : "api.openweathermap.org/data/2.5/forecast?",
  connectionErrorMockPath : "just://wrong_url",
  webErrorMockPath : "https://google.com/non-existed-page",
  timeout : 120.0
)


class RegionByLocationRequestOperationTests: XCTestCase {
  
  var queue: OperationQueue!
  var request: NSMutableURLRequest!
  
  override func setUp() {
    super.setUp()
    queue = OperationQueue()
    request = NSMutableURLRequest()
  }

  func testSuccessOperation() {
    // Prepare
    let operationToTest = RegionByLocationRequestOperation(
      locationContainer: [consts.location] as NSArray,
      request: request
    )
    operationToTest.appKey = consts.key
    operationToTest.endpoint = consts.path
    
    // Execute
    let exp = self.expectation(description: "operation completed!")
    operationToTest.completionBlock = { exp.fulfill() }
    queue.addOperation(operationToTest)
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertTrue(operationToTest.isFinished)
    XCTAssertFalse(operationToTest.isCancelled)
    XCTAssertNil(operationToTest.error)
    XCTAssertNotNil(request.url)
    XCTAssertEqual(request.url?.absoluteString.contains(consts.expectedPath), true)
  }
  
  
}
