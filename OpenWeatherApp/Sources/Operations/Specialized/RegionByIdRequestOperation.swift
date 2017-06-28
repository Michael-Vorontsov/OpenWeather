//
//  RegionByIdRequestOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

//
//  RegionByLocationRequestOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreLocation

/**
 Generate http request for fetching region and forecast data by location
 
 depends on internally injected enpoint and app key.
 */
final class RegionByIdRequestOperation: Operation, AuthRequestOperation {

  var appKey: String?
  var endpoint: String?

  let request: NSMutableURLRequest?
  var result: URLRequest?
  let sid: Int64
  
  private(set) var error: Error? {
    didSet {
      if let error = error { errorBuffer?.add(error) }
    }
  }
  private(set) var errorBuffer: NSMutableArray?
  
  init(
    regionSID: Int64,
    request: NSMutableURLRequest?,
    errorBuffer: NSMutableArray? = nil
  ) {
    self.sid = regionSID
    self.request = request
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
    
    let request = self.request ?? NSMutableURLRequest()
    
    // Generate base URL by endPoint. No request possible without endPoint
    guard
      let appKey = self.appKey,
      let base = self.endpoint,
      var url = URL(string: base)
      else {
        self.error = OperationError.missingData
        self.cancel()
        //TODO: cancel operation and return error
        return
    }
    url = url.appendingPathComponent(consts.path )
    
    let parameters: [String : Any] = [
      consts.metric.key : consts.metric.value,
      consts.sidKey : sid,
      consts.appKey : appKey
    ]
    
    let parametersString = parameters.encodeToGetParameters()
    url = URL(string: "?" + parametersString, relativeTo: url) ?? url
    
    request.url = url
    result = request as URLRequest
  }
  
}

private let consts = (
  path : "forecast",
  metric : (
    key : "units",
    value : "metric"
  ),
  mode : (
    key : "mode",
    value : "json"
  ),
  sidKey : "id",
  appKey : "APPID"
)
