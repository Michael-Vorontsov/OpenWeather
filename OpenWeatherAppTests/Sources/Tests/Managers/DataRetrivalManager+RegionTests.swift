//
//  DataRetrivalManager+RegionTests.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import CoreData
import CoreLocation
@testable import OpenWeatherApp

private let consts = (
  key : "dc886611b26de962e9433c928d4b2b56",
  endpoint : "http://api.openweathermap.org/data/2.5",
  dataModel : "OpenWeatherApp",
  dataModelExt : "momd",
  location : CLLocationCoordinate2D(latitude: 51.5, longitude: 0.1),
  timeout : 150.0
)

class DataRetrivalManager_RegionTests: XCTestCase {
  
  var coreDataContainer: NSPersistentContainer!
  
  override func setUp() {
    super.setUp()
    
    let bundle = Bundle.main
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
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testRetiveCurrentRegion() {
    
    // Test depends on permition granted by user to use geolocation.
    // It will fail if user permit using geolocation for app.

    // Prepare
    let manager = DataRetrivalManager(
      endpoint: consts.endpoint,
      appKey: consts.key,
      dataManager: coreDataContainer
    )
    
    //Execute
    let exp = self.expectation(description: "operation completed!")
    var result: Region?
    var resultError: Error?
    manager.getCurrentRegion { (region, error) in
      result = region
      resultError = error
      exp.fulfill()
    }
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertNotNil(result)
    XCTAssertNil(resultError)
    
  }

  func testRetiveRegionByLocation() {
    
    // Prepare
    let manager = DataRetrivalManager(
      endpoint: consts.endpoint,
      appKey: consts.key,
      dataManager: coreDataContainer
    )
    
    //Execute
    let exp = self.expectation(description: "operation completed!")
    var result: Region?
    var resultError: Error?
    manager.getRegion(forLocation:consts.location) { (region, error) in
      result = region
      resultError = error
      exp.fulfill()
    }
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertNotNil(result)
    XCTAssertNil(resultError)
    XCTAssertEqual(result?.name, "Abbey Wood")
    XCTAssertNotNil(result?.forecasts)
  }

  func testGetRegionBySID() {
    
    // Prepare
    let manager = DataRetrivalManager(
      endpoint: consts.endpoint,
      appKey: consts.key,
      dataManager: coreDataContainer
    )
    
    //Execute
    let exp = self.expectation(description: "operation completed!")
    var result: Region?
    var resultError: Error?
    manager.getRegion(byID: 2648110) { (region, error) in
      result = region
      resultError = error
      exp.fulfill()
    }
    wait(for: [exp], timeout: consts.timeout)
    
    // Check
    XCTAssertNotNil(result)
    XCTAssertNil(resultError)
    XCTAssertEqual(result?.name, "Greater London")
    XCTAssertNotNil(result?.forecasts)
  }
  
}
