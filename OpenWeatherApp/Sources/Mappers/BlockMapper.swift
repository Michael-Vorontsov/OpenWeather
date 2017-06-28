//
//  BlockMapper.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreData

/**
 Create generic mapper, that launch handler block for any specific case.
 Can be very usefull with simple data.
 */
final class BlockMapper<ResultType>: GenericMapper<ResultType> {
  
  typealias MapBlock = (Info) throws -> ResultType
  
  private let handler: MapBlock
  
  init(handler: @escaping MapBlock) {
    self.handler = handler
  }
  
  override func map(info: Info) throws -> ResultType {
    return try handler(info)
  }
}

/**
 same as BlockMapper, but designated to work with core data objects.
 ManagedContext should be given to block as well as collection info.
 */
final class BlockCoredataMapper: GenericCoredataMapper {
  
  typealias MapBlock = (Info, NSManagedObjectContext) throws -> ResultType
  
  private let handler: MapBlock
  
  init(handler: @escaping MapBlock) {
    self.handler = handler
  }
  
  override func map(info: Info) throws -> ResultType {
    guard let context = context else { throw OperationError.coreData }
    return try handler(info, context)
  }
  
}
