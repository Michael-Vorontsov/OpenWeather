//
//  GenericMapper.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreData

/** 
 Generic mapper protocol.
 Mappers shoud be executed on Parse operations to convert Collection data into model data
 */
protocol Mapper {
  associatedtype ResultType
  /**
   Convert collection data(info) into model data.
   Throws error if any.
  */
  func map(info: Info) throws -> ResultType
}

/**
 'Abstract' class.
 It is forbidden to define veraibles as generic protocol types, 
 so generic abstract class requeired to handle it.
 */
class GenericMapper<Object>: Mapper {
  func map(info: Info) throws -> Object {
    assertionFailure("Should be overriden in subclass")
    throw OperationError.other(error: nil)
  }
  
  typealias ResultType = Object
}

/**
 'Abstract' class for mapping CoreData items.
 As NSMnagedObjects depends on threads and context it is unsafe to return them.
 on other hand thread-safe object id can be used.
 */
class GenericCoredataMapper: GenericMapper<NSManagedObjectID> {
  var context: NSManagedObjectContext!
}

