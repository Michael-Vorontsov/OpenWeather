//
//  OperationError.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Composition of all errors
 */
enum OperationError: Error {
  case network(error: Error?)
  case web(code: Int)
  case coreData
  case misformatedData
  case missingData
  case other(error: Error?)
  case geolocationError
}
