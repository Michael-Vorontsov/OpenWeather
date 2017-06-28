//
//  ParseOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

typealias Info = [String : Any]

/**
 Generic operation to parse array collection into array of model objects.
 Should use mapper to execute converion of singular collection info into singular data object.
 */
class ParseOperation<ResultType>: Operation {
  
  let collection: NSArray
  let resultCollection: NSMutableArray?
  let mapper: GenericMapper<ResultType>
  var results = [ResultType]()
  
  internal(set) var error: Error? {
    didSet {
      if let error = error { errorBuffer?.add(error) }
    }
  }
  private(set) var errorBuffer: NSMutableArray?
  
  /**
   get collectuion infos from serializedCollection
   map it into model objects using mapper
   and place it into resultCollection
   */
  init(
    serializedCollection: NSArray,
    resultCollection: NSMutableArray?,
    mapper: GenericMapper<ResultType>,
    errorBuffer: NSMutableArray? = nil
  ) {
    self.collection = serializedCollection
    self.resultCollection = resultCollection
    self.mapper = mapper
    self.errorBuffer = errorBuffer
  }
  
  override func main() {
    guard !isCancelled else { return }
    
    // If any of dependencies was cancelled - cancel
    for subOperation in dependencies {
      if subOperation.isCancelled {
        cancel()
        return
      }
    }
    do {

      for element in collection {
        // If object is not dictionary - it is unproperly marhslled
        guard let info = element as? Info else { throw OperationError.missingData }
        let output = try mapper.map(info: info)
        results.append(output)
        resultCollection?.add(output)
      }
    }
    catch let error as OperationError {
      self.error = error
      cancel()
      return
    }
    catch {
      self.error = OperationError.other(error: error)
      cancel()
      return
    }
  }
  
}
