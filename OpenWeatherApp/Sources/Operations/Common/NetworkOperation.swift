//
//  NetworkOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

/**
 NetworkOperation
 
 Fetching data using provided request into provided buffer.
 
 2nd Part of flow of dependable operations:
  Consturct Request -> Fetch Data -> Serialize JSON -> Parse JSON
 
 Fetch request expected to be constructd by earlier operation,
 Data buffer expected to be empty but consummed by further operations.
 
 If previouse operations failed or cancelled all subsequnt operations should be cancelled as well. 
 
 If error happened operation expeced to be cancelled
 
 NSData and NSURLRequest used to provide flexibility and ability to mutate them in dependant operations after this operation already instantiated.
 */
class NetworkOperation: Operation {
  
  private var dataTask: URLSessionDataTask?
  private var session: URLSession
  
  private(set) var request: NSURLRequest
  private(set) var buffer: NSMutableData?
  
  private(set) var error: Error? {
    didSet {
      if let error = error { errorBuffer?.add(error) }
    }
  }
  private(set) var errorBuffer: NSMutableArray?
  
  override var isAsynchronous: Bool { return true }
  
  override var isCancelled: Bool {
    let taskCanclled = (dataTask?.state == .canceling) || nil != error
    return super.isCancelled || taskCanclled
  }
  
  override var isFinished: Bool {
    guard !isExecuting else { return false }
    guard !isCancelled else { return true }
    if let buffer = buffer, buffer.length > 0 { return true}
    guard let state = dataTask?.state else { return false }
    
    switch state {
    case .running, .suspended:
      return false
    case .canceling, .completed:
      return true
    }
  }
  
  override var isExecuting: Bool {
    if let buffer = buffer, buffer.length > 0 { return false}
    guard let state = dataTask?.state, !isCancelled else { return false }
    switch state {
    case .running:
      return true
    case .canceling, .completed, .suspended:
      return false
    }
  }
  
  override func cancel() {
    dataTask?.cancel()
    super.cancel()
//    self.reportExecutingChanged()
//    self.reportFinishedChanged()
  }
  
  override func start() {

    guard !isCancelled else { return }
    // If buffer contaned data - then it was loaded by other operation, and no additionl actons required
    guard buffer?.length == 0 else {
      defer {
        self.reportExecutingChanged()
      }
      return
    }

    // If any of dependencies was cancelled - cancel
    for subOperation in dependencies {
      if subOperation.isCancelled {
        cancel()

        return
      }
    }
    
    defer {
      self.reportExecutingChanged()
    }
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) in

      defer {
        self.reportExecutingChanged()
        self.reportFinishedChanged()
      }

      guard !self.isCancelled else { return }

      if let data = data, let buffer = self.buffer {
        buffer.append(data)
      }

      if let error = error {
        self.error = OperationError.network(error: error)
        self.cancel()
        return
      }
      
      // If network code in `success` range
      if  let response = response as? HTTPURLResponse, !(200 ... 299 ~= response.statusCode) {
        self.error = OperationError.web(code: response.statusCode)
        self.cancel()
        return
      }
      

    }
    dataTask = task
    task.resume()
  }
  
  init (
    request: NSURLRequest,
    buffer:  NSMutableData,
    session: URLSession = URLSession.shared,
    errorBuffer: NSMutableArray? = nil
  ) {
    self.session = session
    self.request = request
    self.buffer = buffer
    self.errorBuffer = errorBuffer
  }
  
}
