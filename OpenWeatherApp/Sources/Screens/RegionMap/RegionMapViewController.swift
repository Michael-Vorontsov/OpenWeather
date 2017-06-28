//
//  RegionMapViewController.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreData
import MapKit

/*
 Make Region compatible with MapKit directly
 */
extension Region: MKAnnotation {
  public var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(
      latitude: CLLocationDegrees(lat),
      longitude: CLLocationDegrees(lng)
    )
  }
  
  public var title: String? {
    return name
  }
  
  public var subtitle: String? {
    return isCurrent ? consts.current.localize() : ""
  }
  
}

/**
 View controller to present all regions on map,
 add new region (using log tap)
 delete region
 
 after returning back selected region information will be presented.
 */
final class RegionMapViewController: UIViewController, ViewControllerDataManaging, RegionSelecting {
  
  @IBOutlet
  private weak var curtainView: UIVisualEffectView!
  
  @IBOutlet
  private weak var mapView: MKMapView!

  var dataManager: DataRetrivalManager!
  
  var selectionHandler: ((Region?) -> Void)?
  var selectedRegion: Region? {
    didSet {
      title = selectedRegion?.name

      if let selectedRegion = selectedRegion {
        mapView?.selectAnnotation(selectedRegion, animated: true)
      } else {
        mapView?.deselectAnnotation(selectedRegion, animated: true)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadAnotations()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    selectionHandler?(selectedRegion)
  }
  
  /*
   Fecth result controller helps to update ui on changes to Regions.
 */
  fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Region>! = {
    guard let name = Region.entity().name else { return nil }
    let request = NSFetchRequest<Region>(entityName: name)
    
    request.sortDescriptors = [
      NSSortDescriptor(key: consts.sortKey, ascending: true),
    ]
    let fetchedController = NSFetchedResultsController(
      fetchRequest: request,
      managedObjectContext: self.dataManager.mainContext(),
      sectionNameKeyPath: nil,
      cacheName: nil
    )
    fetchedController.delegate = self
    _ = try? fetchedController.performFetch()
    return fetchedController
  }()
  
  fileprivate func reloadAnotations() {
    mapView.removeAnnotations(mapView.annotations)
    mapView.addAnnotations(fetchedResultsController.fetchedObjects!)
    
    if let selectedRegion = selectedRegion {
      mapView.selectAnnotation(selectedRegion, animated: true)
    }
  }
  
  @IBAction
  fileprivate func mapTouched(_ sender: UILongPressGestureRecognizer) {
    guard sender.state == .recognized else {
      return
    }
    
    let location = sender.location(in: mapView)
    let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
    mapView.setCenter(coordinate, animated: true)
    askForNewRegion(coordinate: coordinate)
  }
  
  fileprivate func askForNewRegion(coordinate: CLLocationCoordinate2D) {
    let alert = UIAlertController(
      title: consts.addRegionAlert.title,
      message: consts.addRegionAlert.message,
      preferredStyle: .actionSheet
    )
    
    alert.addAction(UIAlertAction(
      title: consts.addRegionAlert.confirm,
      style: .default ) { [unowned self] _ in
        self.requestRegion(at: coordinate)
        alert.dismiss(animated: true, completion: nil)
      })
    
    alert.addAction(UIAlertAction(
      title: consts.addRegionAlert.cancel,
      style: .cancel
    ) { _ in
      alert.dismiss(animated: true, completion: nil)
    })
    self.present(alert, animated: true, completion: nil)
    
  }
  
  fileprivate func requestRegion(at coordinate: CLLocationCoordinate2D) {
    curtainView.isHidden = false
    dataManager.getRegion(forLocation: coordinate) { (region, error) in
      self.curtainView.isHidden = true
      if let error = error {
        self.showErrorAlert(error: error)
      }
      if let region = region {
        self.selectedRegion = region
      }
    }
  }
 
  func deleteRegion(_ sender: UIButton) {
    let request = NSFetchRequest<Region>(entityName: Region.entity().name!)
    request.predicate = NSPredicate(format: consts.sidPredicate, sender.tag)
    guard
      let fetchResult = try? dataManager.mainContext().fetch(request),
      let region = fetchResult.last,
      let context = region.managedObjectContext
      else { return }
    
    let message = String(format: consts.deleteRegionAlert.messageFormat, region.name ?? "")
    let alert = UIAlertController(
      title: consts.deleteRegionAlert.title,
      message: message,
      preferredStyle:.actionSheet
    )
    alert.addAction(UIAlertAction(
      title: consts.deleteRegionAlert.confirm,
      style: .destructive) { _ in
        context.delete(region)
        try? context.save()
        alert.dismiss(animated: true, completion: nil)
    })
    alert.addAction(UIAlertAction(
      title: consts.deleteRegionAlert.cancel,
      style: .cancel) { _ in
        alert.dismiss(animated: true, completion: nil)
    })
    self.present(alert, animated: true, completion: nil)
    
  }
  
}

extension RegionMapViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let region = view.annotation as? Region {
      selectedRegion = region
    } else {
      selectedRegion = nil
    }
  }
  
  func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    if view.annotation === selectedRegion {
      selectedRegion = nil
    }
    view.layer.removeAllAnimations()
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    guard let region = annotation as? Region else {
      return nil
    }
    let reuseId = region.isCurrent ? consts.reuseId.current : consts.reuseId.normal
    if let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) {
      view.annotation = region
      setupCallouts(view: view, region: region)
      return view
    }
    
    let view = MKPinAnnotationView(annotation: region, reuseIdentifier: reuseId)
    view.pinTintColor = region.isCurrent ? UIColor.blue : UIColor.yellow
    view.canShowCallout = true
    let button = UIButton(type: .system)
    button.setTitle(consts.delete.localize(), for: .normal)
    view.detailCalloutAccessoryView = button
    button.addTarget(
      self,
      action: #selector(deleteRegion(_:)),
      for: .allEvents
    )
    let imageView = UIImageView(frame: consts.calloutIconFrame)
    view.rightCalloutAccessoryView = imageView
    
    setupCallouts(view: view, region: region)
    return view
  }
  
  func setupCallouts(view: MKAnnotationView, region: Region) {
    if
      let imageView = view.rightCalloutAccessoryView as? UIImageView,
      let iconName = (region.forecasts?.firstObject as? Forecast)?.icon,
      let image = UIImage(named: iconName) {
      imageView.isHidden = false
      imageView.image = image
    }
    else {
      view.rightCalloutAccessoryView?.isHidden = true
    }
    if let button = view.detailCalloutAccessoryView as? UIButton {
      button.isEnabled = !region.isCurrent
      button.tag = Int(region.sid)
    }
  }
}

extension RegionMapViewController: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    reloadAnotations()
  }
  
}

private let consts = (
  current : "Current",
  sortKey : "sid",
  reuseId : (
    normal : "pinView",
    current : "currentPinView"
  ),
  delete : "Delete",
  calloutIconFrame : CGRect(x: 0, y: 0, width: 50, height: 50),
  addRegionAlert : (
    title : "Add region",
    message : "Please confirm",
    confirm : "Ok",
    cancel : "Cancel"
  ),
  deleteRegionAlert : (
    title : "Delete region?",
    messageFormat : "Do you want to delete %@ ?",
    confirm : "Yes, sure",
    cancel : "Cance"
  ),
  sidPredicate : "sid = %i",
  tempFormat : "%.2f ℃"
)
