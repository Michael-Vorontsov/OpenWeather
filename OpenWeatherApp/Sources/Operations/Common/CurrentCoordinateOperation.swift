//
//  CurrentCoordinateOperation.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreLocation

/**
 Retrive current location using CLLocationManager
 */
final class CurrentLocationOperation: Operation {
  
  fileprivate var locationManager: CLLocationManager? = nil
  fileprivate(set) var error: Error? {
    didSet {
      if let error = error { errorBuffer?.add(error) }
    }
  }
  private(set) var errorBuffer: NSMutableArray?
  private(set) var container: NSMutableArray?
  var currentLocation: CLLocation? = nil
  
  
  override var isAsynchronous: Bool { return true }
  
  override var isFinished: Bool {
    return isCancelled || currentLocation != nil || error != nil
  }
  
  override var isExecuting: Bool {
    return !isCancelled && locationManager != nil && error == nil
  }
  
  override func cancel() {
    self.willChangeValue(forKey: "isFinished")
    self.willChangeValue(forKey: "isExecuting")
    locationManager?.stopUpdatingLocation()
    locationManager?.delegate = nil
    locationManager = nil
    super.cancel()
    self.didChangeValue(forKey: "isFinished")
    self.didChangeValue(forKey: "isExecuting")
  }
  
  override func start() {
    
    guard !isCancelled else { return }
    
    // If any of dependencies was cancelled - cancel
    for subOperation in dependencies {
      if subOperation.isCancelled {
        cancel()
        return
      }
    }
    
    // LocationManager had to be initiated at main thread
    DispatchQueue.main.async {
      let locationManager = CLLocationManager()
      locationManager.delegate = self
      self.locationManager = locationManager
      locationManager.requestAlwaysAuthorization()
      
      defer { self.reportExecutingChanged() }
      locationManager.startUpdatingLocation()
    }
    
  }
  
  init(container: NSMutableArray?, errorBuffer: NSMutableArray? = nil) {
    self.container = container
    self.errorBuffer = errorBuffer
  }
  
}

extension CurrentLocationOperation: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    // Place user location into container report completion
    defer {
      self.reportExecutingChanged()
      self.reportFinishedChanged()
    }
    
    currentLocation = locations.last
    if let location = currentLocation, let container = container {
      container.add(location)
    }
    locationManager?.stopUpdatingLocation()
    locationManager = nil
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    // If location manager forbdden - cancell operation and report error
    switch status {
    case .denied, .restricted:
      self.error = OperationError.geolocationError
      cancel()
    default:
      break;
    }
  }
  
  func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
    self.error = OperationError.geolocationError
    cancel()
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    self.error = OperationError.geolocationError
    cancel()
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    self.error = OperationError.geolocationError
    cancel()
  }
  
}
