//
//  CarouselTableViewCell.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

class CarouselTableViewCell: UITableViewCell {
  
  @IBOutlet
  weak var dateLabel: UILabel!
  
  @IBOutlet
  private weak var collectionView: UICollectionView!
  
  /**
    Allows to setup horizontal offset for specific carousel
   */
  var scrollOffset: CGFloat {
    set {
      var offset = collectionView.contentOffset
      offset.x = newValue
      collectionView.contentOffset = offset
    }
    get {
      return collectionView.contentOffset.x
    }
  }

  func setCollectionViewDataSourceDelegate
    <DelegateAndDatasource: UICollectionViewDataSource & UICollectionViewDelegate>(
    _ dataSourceDelegate: DelegateAndDatasource,
    forRow row: Int
  ) {
    
    collectionView.delegate = dataSourceDelegate
    collectionView.dataSource = dataSourceDelegate
    collectionView.tag = row
    collectionView.reloadData()
  }
}
