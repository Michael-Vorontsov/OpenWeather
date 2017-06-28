//
//  AppDelegate.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/25/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreData

/**
 Protocol describing view controllers that shoud work with data
 */
protocol ViewControllerDataManaging: class {
  var dataManager: DataRetrivalManager! { get set }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ViewControllerDataManaging {

  var window: UIWindow?
  var dataManager: DataRetrivalManager!

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    let manager = DataRetrivalManager(
      endpoint: consts.endpoint,
      appKey: consts.key,
      dataManager: persistentContainer
    )
    self.dataManager = manager
    
    if let navigationController = window?.rootViewController as? UINavigationController,
      let rootController = navigationController.topViewController as? ViewControllerDataManaging {
      rootController.dataManager = manager
    }
    return true
  }

  // MARK: - Core Data stack
  // Default template imlementation of CoreData persisten container
  lazy var persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: consts.dataModel)
      container.loadPersistentStores(completionHandler: { (storeDescription, error) in
          if let error = error as NSError? {
              fatalError("Unresolved error \(error), \(error.userInfo)")
          }
      })
      return container
  }()

}

private let consts = (
  key : "dc886611b26de962e9433c928d4b2b56",
  endpoint : "http://api.openweathermap.org/data/2.5",
  dataModel : "OpenWeatherApp",
  dataModelExt : "momd"
)
