//
//  ManagedObjectParseOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreData

/**
 Similar to Parse operation, but depends on Context, and return ObjectIDs of parsed data objects.
 */
class ManagedObjectParseOperation: ParseOperation<NSManagedObjectID> {
  
  let context: NSManagedObjectContext
  
  init(
    context: NSManagedObjectContext,
    serializedCollection: NSArray,
    resultCollection: NSMutableArray?,
    mapper: GenericCoredataMapper,
    errorBuffer: NSMutableArray? = nil
  ) {
    self.context = context
    mapper.context = context
    
    super.init(
      serializedCollection: serializedCollection,
      resultCollection: resultCollection,
      mapper: mapper,
      errorBuffer: errorBuffer
    )
  }
  
  override func main() {
    
    context.performAndWait {
      super.main()
      do {
        try self.context.save(recursive: true)
      }
      catch {
        super.error = OperationError.coreData
      }
    }
  }
  
}
