//
//  JSONSerialisationOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

enum SerializationError: Error {
  case unmarshaledError(error: Error)
}

/**
 SerialisationOperation
 
 Convert json data into  Array collection.
 If JSON contains only one object - wrap it into array as well
 
 Should take data from buffer to place it into outputCOllection.
 */
class SerializationOperation: Operation {
  
  let collection: NSMutableArray?
  let buffer: NSData

  private(set) var error: Error? {
    didSet {
      if let error = error { errorBuffer?.add(error) }
    }
  }
  private(set) var errorBuffer: NSMutableArray?
    
  init(
    dataBuffer: NSData,
    outputCollection: NSMutableArray?,
    errorBuffer: NSMutableArray? = nil
    
  ) {
    collection = outputCollection
    buffer = dataBuffer
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
      let jsonObject = try JSONSerialization.jsonObject(
        with: buffer as Data,
        options: []
      )
      // If seirialization result array - append it
      if let jsonObject = jsonObject as? [Any] {
        collection?.addObjects(from: jsonObject)
      } else {
        //otherwise add it as single object
        collection?.add(jsonObject)
      }
    } catch {
      self.error = OperationError.misformatedData
      cancel()
    }
  }

}
