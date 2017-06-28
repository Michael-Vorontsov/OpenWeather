//
//  NSManagedObjectContext+SaveRecursive.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
  /**
   Propagade changes in context recusively up to Persisten Store.
   */
  func save(recursive: Bool) throws {
    try save()
    if recursive , let parentContext = self.parent {
      try parentContext.save(recursive: true)
    }
  }
}
