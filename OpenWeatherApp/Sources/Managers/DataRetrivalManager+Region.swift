//
//  DataRetrivalManager+Region.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

typealias RegionRequestResultBlock = (Region?, Error?) -> Void

/**
 Protcol for data rettrival manager responsible for fetching Region data.
 It is usefull to create protocols and extensions for each data set. 
 It helps to reduce dependecies and create unit tests for particular data.
 */
protocol RegionForecastRetriving {
  func getRegion(byID regionSID: Int64, completion: @escaping RegionRequestResultBlock)
  func getRegion(forLocation location: CLLocationCoordinate2D, completion:  @escaping RegionRequestResultBlock)
  func getCurrentRegion(completion: @escaping RegionRequestResultBlock)
}


/**
 Extension for DataRetrival manager to handle all Region requests.
 Separated into extension helps create extensions for each particular data
 (in this project however it is Region only)
 */
extension DataRetrivalManager: RegionForecastRetriving {
  
  /**
   Request forecasts and region data for regions with given ID
   
   Task composed from atomic operations:
   1. Create http request
   2. Request data from server
   3. Deserialize data into Collection
   4. Parse collection into model data and save to coredata (for SID)
   5. Convert model data to main queue and execute completion block
   
   If error happened on any operation, all sucsequent operations will be halted.
   Any possible errors accumulated into separate error buffer.
   */
  func getRegion(byID regionSID: Int64, completion: @escaping RegionRequestResultBlock) {
    
    // Create accumulator for errors
    let errorBuffer = NSMutableArray()
    
    /*
     All operations created at once.
     Dependant operations should share some mutable buffer(accumulators) to share results beween each other.
     
     For example Network operation created before http request was generated.
     So it was intialized with empty mutable http request (as accumulator).
     It waits until dependant operation had been executed, (and filled container).
     After it takes http request from this container and make request.
     */
    let request = NSMutableURLRequest()
    let requestOperation = RegionByIdRequestOperation(
      regionSID: regionSID,
      request: request,
      errorBuffer: errorBuffer
    )
    /*
     endpoint and appKey injected by data manager. 
     It will be better to customize operation queue and inject all necessary dependacies while scheduling new operations, however this task is too complext for such as small sample project.
     */
    requestOperation.endpoint = self.endpoint
    requestOperation.appKey = self.appKey
    queue.addOperation(requestOperation)
    
    let buffer = NSMutableData()
    let netOperation = NetworkOperation(
      request: request,
      buffer: buffer,
      errorBuffer: errorBuffer
    )
    netOperation.addDependency(requestOperation)
    queue.addOperation(netOperation)
    
    let infosCollection = NSMutableArray()
    let serializeOperation = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: infosCollection,
      errorBuffer: errorBuffer
    )
    serializeOperation.addDependency(netOperation)
    queue.addOperation(serializeOperation)
    
    let regions = NSMutableArray()
    let parseOperation = ManagedObjectParseOperation(
      context: dataContext(),
      serializedCollection: infosCollection,
      resultCollection: regions,
      mapper: BlockCoredataMapper(handler: { (info, context) -> NSManagedObjectID in
        
        guard  let sid = (info as NSDictionary).value(forKeyPath: consts.region.idKeypath) as? Int64 else {
          throw OperationError.missingData
        }
        let request = NSFetchRequest<Region>(entityName: Region.entity().name!)
        request.predicate = NSPredicate(format: consts.region.predicate.sid, sid)
        // fetch existed Region or create new if not exists yet
        let region = (try? context.fetch(request))?.last ?? Region(context: context)
        try self.update(region: region, info: info)
        return region.objectID
      }),
      errorBuffer: errorBuffer
    )
    parseOperation.addDependency(serializeOperation)
    queue.addOperation(parseOperation)
    
    let mainContext = self.mainContext()
    // Execute completion block on main queue after last operation completed
    let completionOperation = BlockOperation {
      
      // Get first error from buffer to report
      let firstError = errorBuffer.firstObject as? Error
      
      // Try to fetch object in main thread
      if
        let region = regions.lastObject as? NSManagedObjectID,
        let result = mainContext.object(with: region) as? Region
      {
        completion(result, firstError)
        return
      }
      completion(nil, firstError)
    }
    
    completionOperation.addDependency(parseOperation)
    OperationQueue.main.addOperation(completionOperation)
    
  }
  
  /**
   Request forecasts and region data for specific coordinates
   
   Task composed from atomic operations:
   1. Create http request
   2. Request data from server
   3. Deserialize data into Collection
   4. Parse collection into model data and save to coredata (for SID)
   5. Convert model data to main queue and execute completion block
   
   If error happened on any operation, all sucsequent operations will be halted.
   Any possible errors accumulated into separate error buffer.
   */
  func getRegion(forLocation location: CLLocationCoordinate2D, completion:  @escaping RegionRequestResultBlock) {
    
    let errorBuffer = NSMutableArray()
    let location = CLLocation(latitude: location.latitude, longitude: location.longitude)
    let request = NSMutableURLRequest()
    let requestOperation = RegionByLocationRequestOperation(
      locationContainer: [location] as NSArray,
      request: request,
      errorBuffer: errorBuffer
    )
    requestOperation.endpoint = self.endpoint
    requestOperation.appKey = self.appKey
    queue.addOperation(requestOperation)
    
    let buffer = NSMutableData()
    let netOperation = NetworkOperation(
      request: request,
      buffer: buffer,
      errorBuffer: errorBuffer
    )
    netOperation.addDependency(requestOperation)
    queue.addOperation(netOperation)
    
    let infosCollection = NSMutableArray()
    let serializeOperation = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: infosCollection,
      errorBuffer: errorBuffer
    )
    serializeOperation.addDependency(netOperation)
    queue.addOperation(serializeOperation)
    
    let regions = NSMutableArray()
    
    let parseOperation = ManagedObjectParseOperation(
      context: dataContext(),
      serializedCollection: infosCollection,
      resultCollection: regions,
      mapper: BlockCoredataMapper(handler: { (info, context) -> NSManagedObjectID in
        
        let sid = (info as NSDictionary).value(forKeyPath: consts.region.idKeypath) as? Int64 ?? 0
        let request = NSFetchRequest<Region>(entityName: Region.entity().name!)
        request.predicate = NSPredicate(format: consts.region.predicate.sid, sid)
        let region = (try? context.fetch(request))?.last ?? Region(context: context)
        try self.update(region: region, info: info)
        return region.objectID
      }),
      errorBuffer: errorBuffer
    )
    parseOperation.addDependency(serializeOperation)
    queue.addOperation(parseOperation)
    
    let mainContext = self.mainContext()
    // Execute completion block on main queue after last operation completed
    let completionOperation = BlockOperation {

      // Get first error from buffer to report
      let firstError = errorBuffer.firstObject as? OperationError
      
      // Try to fetch object in main thread
      if
        let region = regions.lastObject as? NSManagedObjectID,
        let result = mainContext.object(with: region) as? Region
      {
        completion(result, firstError)
        return
      }
      completion(nil, firstError)
    }
    
    completionOperation.addDependency(parseOperation)
    OperationQueue.main.addOperation(completionOperation)

  }
  
  /**
   Request forecast data for region at  current location
   
   Task composed from atomic operations:
   1. Get current location 
   2. Create http request 
   3. Request data from server
   4. Deserialize data into Collection
   5. Parse collection into model data and save to coredata (as Current Region).
   6. Convert model data to main queue and execute completion block
   
   If error happened on any operation, all sucsequent operations will be halted.
   Any possible errors accumulated into separate error buffer.
   */
  func getCurrentRegion(completion: @escaping RegionRequestResultBlock) {
    
    let errorBuffer = NSMutableArray()

    let locationContainer = NSMutableArray()
    let locationOperation = CurrentLocationOperation(
      container: locationContainer,
      errorBuffer: errorBuffer
    )
    queue.addOperation(locationOperation)
    
    let request = NSMutableURLRequest()
    let requestOperation = RegionByLocationRequestOperation(
      locationContainer: locationContainer,
      request: request,
      errorBuffer: errorBuffer
    )
    requestOperation.endpoint = self.endpoint
    requestOperation.appKey = self.appKey
    requestOperation.addDependency(locationOperation)
    queue.addOperation(requestOperation)
    
    let buffer = NSMutableData()
    let netOperation = NetworkOperation(
      request: request,
      buffer: buffer,
      errorBuffer: errorBuffer
    )
    netOperation.addDependency(requestOperation)
    queue.addOperation(netOperation)
    
    let infosCollection = NSMutableArray()
    let serializeOperation = SerializationOperation(
      dataBuffer: buffer,
      outputCollection: infosCollection,
      errorBuffer: errorBuffer
    )
    serializeOperation.addDependency(netOperation)
    queue.addOperation(serializeOperation)
    
    let regions = NSMutableArray()
    let parseOperation = ManagedObjectParseOperation(
      context: dataContext(),
      serializedCollection: infosCollection,
      resultCollection: regions,
      mapper: BlockCoredataMapper(handler: { (info, context) -> NSManagedObjectID in
        
        let request = NSFetchRequest<Region>(entityName: Region.entity().name!)
        request.predicate = NSPredicate(format: consts.region.predicate.current, true as CVarArg)
        let currentRegion = (try? context.fetch(request))?.last ?? Region(context: context)
        currentRegion.isCurrent = true
        try self.update(region: currentRegion, info: info)
        return currentRegion.objectID
      }),
      errorBuffer: errorBuffer
    )
    parseOperation.addDependency(serializeOperation)
    queue.addOperation(parseOperation)
    
    let mainContext = self.mainContext()
    // Execute completion bloc on main queue after last operation completed
    let completionOperation = BlockOperation {
      
      // Get first error from buffer to report
      let firstError = errorBuffer.firstObject as? Error
      
      // Try to fetch object in main thread
      if
        let region = regions.lastObject as? NSManagedObjectID,
        let result = mainContext.object(with: region) as? Region
      {
        completion(result, firstError)
        return
      }
      completion(nil, firstError)
    }
    
    completionOperation.addDependency(parseOperation)
    OperationQueue.main.addOperation(completionOperation)
  }
  
}

// Helper internal extension to map Region and Forecast data
fileprivate extension DataRetrivalManager {
  fileprivate func update(region: Region, info: Info) throws {
    
    guard
      let regionInfo = info[consts.region.key] as? Info,
      let locationInfo = regionInfo[consts.region.location.key] as? Info,
      let lng = locationInfo[consts.region.location.lng] as? Float,
      let lat = locationInfo[consts.region.location.lat] as? Float
    else {
      throw OperationError.missingData
    }
    region.name = (regionInfo[consts.region.name] as? String)
    region.country = (regionInfo[consts.region.country] as? String)
    region.sid = (regionInfo[consts.region.sid] as? Int64) ?? 0
    region.lng = lng
    region.lat = lat
    if let oldForecasts = region.forecasts {
      region.removeFromForecasts(oldForecasts)
    }
    
    if let forecastInfos = info[consts.forecast.key] as? [Info] {
      for info in forecastInfos {
        let forecast = Forecast(context: region.managedObjectContext!)
        forecast.region = region
        try self.update(forecast: forecast, info: info)
      }
    }
    
  }
  
  fileprivate func update(forecast: Forecast, info: Info) throws {
    let timeInterval = info[consts.forecast.date] as? TimeInterval ?? 0
    let time = Date(timeIntervalSince1970: timeInterval)
    let calendar = Calendar.current
    let date = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: time)
    forecast.day = date as NSDate?
    forecast.time = time as NSDate?
    
    if let weatherInfo = info[consts.forecast.weather.key] as? Info {
      forecast.temp = weatherInfo[consts.forecast.weather.temp] as! Float
    }
    
    if let windInfo = info[consts.forecast.wind.key] as? Info {
      forecast.windSpeed = windInfo[consts.forecast.wind.speed] as! Float
      forecast.windDir = windInfo[consts.forecast.wind.direction] as! Float
    }
    if let addInfo = info[consts.forecast.extra.key] as? [Info] {
      forecast.icon = addInfo.last?[consts.forecast.extra.icon] as? String
    }
  }
}

private let consts = (
  
  region : (
    predicate : (
      sid : "sid = %i",
      current : "isCurrent = %@"
    ),
    idKeypath : "city.id",
    key : "city",
    sid : "id",
    name : "name",
    country : "country",
    location : (
      key : "coord",
      lng : "lon",
      lat : "lat"
    )
  ),
  forecast : (
    key : "list",
    date : "dt",
    weather : (
      key : "main",
      temp : "temp"
    ),
    wind : (
      key : "wind",
      speed : "speed",
      direction : "deg"
    ),
    extra : (
      key : "weather",
      icon : "icon"
    )
  )
)
