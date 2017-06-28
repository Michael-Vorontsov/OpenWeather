//
//  RegionDetailsViewController.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreData

/**
 Protocol to establish connection between Region details and Region selection
 */
protocol RegionSelecting: class {
  var selectedRegion: Region? { get set }
  var selectionHandler: ((Region?) -> Void)? { get set}
}

/**
 Presnet information about current region, and forecast.
 Forecasts grouped by day, and arranged by time.
 */
final class RegionDetailsViewController: UITableViewController, ViewControllerDataManaging {
  
  var dataManager: DataRetrivalManager!
  
  //MARK: - Public overrides

  override func viewDidLoad() {
    super.viewDidLoad()
    // remove table view segments after last cell
    self.refreshControl?.addTarget(self, action: #selector(reloadSelectedRegion), for: .allEvents)
    self.tableView.tableFooterView = UIView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard nil != dataManager else {
      assertionFailure("Data manager required!")
      return
    }
    reloadSelectedRegion()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    title = nil
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    if let destination = segue.destination as? ViewControllerDataManaging {
      destination.dataManager = dataManager
    }
    if let destination = segue.destination as? RegionSelecting {
      destination.selectedRegion = selectedRegion
      destination.selectionHandler = { [weak self] (region) in
        self?.selectedRegion = region
      }
    }
  }
  
  //MARK: - Internal methods
  fileprivate var selectedRegion: Region? {
    didSet {
      defer {
        _ = try? self.fetchedResultsController?.performFetch()
        self.tableView.reloadData()
      }
      
      guard let selectedRegion = selectedRegion, var title = selectedRegion.name else {
        self.title = consts.pending.localize()
        self.fetchedResultsController?.fetchRequest.predicate = createPredicateForCurretRegion()
        return
      }
      if selectedRegion.isCurrent {
        let format = consts.format.currentRegion.localize()
        title = String(format: format, title)
        self.fetchedResultsController?.fetchRequest.predicate = createPredicateForCurretRegion()
      } else {
        self.fetchedResultsController?.fetchRequest.predicate = createPredicateForRegion(region: selectedRegion)
        
      }
      self.title = title
    }
  }
  
  fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Forecast>?  = {
    return self.createFetchedRequestController()
  }()
  
  fileprivate func createPredicateForRegion(region: Region) -> NSPredicate {
    let sid = region.sid
    return NSPredicate(format: consts.predicates.selected, sid)
  }
  
  fileprivate func createPredicateForCurretRegion() -> NSPredicate {
    return NSPredicate(format: consts.predicates.current, true as CVarArg)
  }
  
  fileprivate func createFetchedRequestController() -> NSFetchedResultsController<Forecast>? {
    guard let name = Forecast.entity().name else { return nil }
    let request = NSFetchRequest<Forecast>(entityName: name)
    
    if let selectedRegion = self.selectedRegion {
      request.predicate = createPredicateForRegion(region: selectedRegion)
    } else {
      request.predicate = createPredicateForCurretRegion()
    }
    request.sortDescriptors = [
      NSSortDescriptor(key: consts.sortKeys.day, ascending: true),
      NSSortDescriptor(key: consts.sortKeys.time, ascending: true)
    ]
    let fetchedController = NSFetchedResultsController(
      fetchRequest: request,
      managedObjectContext: dataManager.mainContext(),
      sectionNameKeyPath: consts.sortKeys.day,
      cacheName: nil
    )
    _ = try? fetchedController.performFetch()
    self.tableView.reloadData()
    return fetchedController
  }
  
  func reloadSelectedRegion() {
    if refreshControl?.isRefreshing == false {
      refreshControl?.beginRefreshing()
    }
    let comletionHandler: RegionRequestResultBlock = { ( region, error) in
      self.refreshControl?.endRefreshing()
      self.selectedRegion = region
      if nil != error {
        self.showErrorAlert(error: error)
      }
    }
    
    if let selectedRegion = selectedRegion {
      dataManager.getRegion(byID: selectedRegion.sid, completion: comletionHandler)
    } else {
      dataManager?.getCurrentRegion(completion: comletionHandler)
    }
  }
  
  fileprivate lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .full
    return formatter
  }()
  
  fileprivate lazy var timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }()
  

  //MARK: - Table view
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.fetchedResultsController?.sections?.count ?? 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: consts.identifiers.carousel,
      for: indexPath
    )
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let tableViewCell = cell as? CarouselTableViewCell else { return }
    
    tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
    
    
    guard
      let fetchedResultsController = fetchedResultsController,
      let sectionsInfo = fetchedResultsController.sections,
      indexPath.row < sectionsInfo.count else {
        return
    }
    let sectionInfo = sectionsInfo[indexPath.row]
    if let sectionDate = (sectionInfo.objects?.first as? Forecast)?.day {
      tableViewCell.dateLabel.text = dateFormatter.string(from: sectionDate as Date)
    }
  }
  
}

//MARK: - Collection view
extension RegionDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int) -> Int
  {
    let sectionIndex = collectionView.tag
    guard
      let fetchedResultsController = fetchedResultsController,
      let sectionsInfo = fetchedResultsController.sections,
      sectionIndex < sectionsInfo.count else {
        return 0
    }
    let sectionInfo = sectionsInfo[sectionIndex]
    return sectionInfo.numberOfObjects
  }
  
  func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: consts.identifiers.collectionCell,
      for: indexPath
    )
    cell.layoutIfNeeded()
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard
      let cell = cell as? CollectionViewCell,
      let fetchedResultsController = fetchedResultsController
      else { return }
    let sectionIndex = collectionView.tag
    let resolvedIndexPath = IndexPath(item: indexPath.item, section: sectionIndex)
    let object = fetchedResultsController.object(at: resolvedIndexPath)
    
    cell.temperatureLabel.text = String(format: consts.format.temp, object.temp)
    let iconName =  object.icon ?? consts.placeholderIcon
    cell.iconImageView.image = UIImage(named: iconName)
    if let time = object.time {
      cell.timeLabel.text = timeFormatter.string(from: time as Date)
    } else {
      cell.timeLabel.text = nil
    }
    cell.layoutIfNeeded()
  }
}

//MARK: - Constants
private let consts = (
  placeholderIcon : "00",
  pending : "Pending",
  
  predicates : (
    current : "region.isCurrent == %@",
    selected : "region.sid == %i"
  ),
  sortKeys : (
    day : "day",
    time : "time"
  ),
  identifiers : (
    carousel : "CarouselIdentifier",
    collectionCell : "Cell"
  ),
  format : (
    currentRegion : "Current - %@",
    temp : "%.2f ℃"
  )
)
 
