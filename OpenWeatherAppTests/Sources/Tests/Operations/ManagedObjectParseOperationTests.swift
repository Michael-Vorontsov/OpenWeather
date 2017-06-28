//
//  CoredataParseOperationTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import CoreData

@testable import OpenWeatherApp

private let consts = (
  successSingleCollection : [["id" : 0]],
  dataModel : "TestModel",
  dataModelExt : "momd",
  timeout : 120.0
)

class ManagedObjectParseOperationTests: XCTestCase {
    
  
  var queue: OperationQueue!
  var infoCollection: NSArray!
  var resultCollection: NSMutableArray!
  var coreDataContainer: NSPersistentContainer!
  
  override func setUp() {
    super.setUp()
    
    let bundle = Bundle(for: type(of: self))
    let url = bundle.url(
      forResource: consts.dataModel,
      withExtension: consts.dataModelExt
    )!
    let model = NSManagedObjectModel(contentsOf: url)!
    
    coreDataContainer = NSPersistentContainer(
      name: consts.dataModel,
      managedObjectModel: model
    )
    coreDataContainer.loadPersistentStores { _ in }
    queue = OperationQueue()
    resultCollection = NSMutableArray()
  }
  
  func testSuccessParsing() {
    
    // Prepare
    infoCollection = consts.successSingleCollection as NSArray
    
    let blockMapper = BlockCoredataMapper { (info, context) in
      let object = SampleObject(context: context)
      object.sid = info["id"] as? Int64 ?? 0
      return object.objectID
    }
    
    let operationToTest = ManagedObjectParseOperation(
      context: coreDataContainer.newBackgroundContext(),
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
    
    let blockMapper = BlockCoredataMapper { (info, context) in
      throw OperationError.missingData
    }
    
    let operationToTest = ManagedObjectParseOperation(
      context: coreDataContainer.newBackgroundContext(),
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
    
    let blockMapper = BlockCoredataMapper { (info, context) in
      let object = SampleObject(context: context)
      object.sid = info["id"] as? Int64 ?? 0
      return object.objectID
    }
    
    let operationToTest = ManagedObjectParseOperation(
      context: coreDataContainer.newBackgroundContext(),
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
