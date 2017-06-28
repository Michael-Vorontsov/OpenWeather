//
//  DataRetrivalManager.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreData

/**
 Protocol for operations that requiere auth key and endpoint.
 */
protocol AuthRequestOperation {
  var appKey: String? { get set }
  var endpoint: String? {get set }
}

/**
 Data manager.
 
 Responsible for handling app-specific requests, and storing  data.
 
 Incapsulate inside operation queue and core data stack.
 Able to provide main and backgorund core data contexts.
 
 Handling enpoint and app key, and injecting them into dedicated request generators.
 */
class DataRetrivalManager {
  
  private(set) lazy var queue: OperationQueue = {
    let queue = OperationQueue()
    return queue
  }()
  
  let appKey: String
  let endpoint: String
  private let coreDataManager: NSPersistentContainer
  
  //* main context for requesting objects from core data to present on UI
  func mainContext() -> NSManagedObjectContext {
    return coreDataManager.viewContext
  }
  
  /**
 Creats data contexts for parsing data objects at backgound thread to core data
  all changes after (!) saving should be captured by FetchResultControllers
 */
  func dataContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.parent = coreDataManager.viewContext
    return context
  }
  
  /**
   init new data retrival manager with enpoint, app key and core data persistent container
  */
  init (endpoint: String, appKey: String, dataManager: NSPersistentContainer) {
    self.endpoint = endpoint
    self.appKey = appKey
    self.coreDataManager = dataManager
  }
  
}
