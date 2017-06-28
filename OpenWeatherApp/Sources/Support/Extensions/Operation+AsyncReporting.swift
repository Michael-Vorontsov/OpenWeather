//
//  Operation+AsyncReporting.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 Simple extension to notify KVO about changing operation execution states
 (mandatory for subclassing async operations)
 */
extension Operation {
  
  func reportExecutingChanged() {
    self.willChangeValue(forKey: "isExecuting")
    self.didChangeValue(forKey: "isExecuting")
  }
  
  func reportFinishedChanged() {
    self.willChangeValue(forKey: "isFinished")
    self.didChangeValue(forKey: "isFinished")
  }
}
