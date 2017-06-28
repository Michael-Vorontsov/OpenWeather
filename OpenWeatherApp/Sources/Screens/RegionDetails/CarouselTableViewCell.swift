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
