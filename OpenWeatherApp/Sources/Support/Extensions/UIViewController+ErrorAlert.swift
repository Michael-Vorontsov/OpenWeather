//
//  UIViewController+ErrorAlert.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

extension UIViewController {
  
  /**
   Present alert about error at any view controller.
   
   Message is very general, and same for any error.
   */
  func showErrorAlert(error: Error?)  {
    let alert = UIAlertController(
      title: consts.title.localize(),
      message: consts.message.localize(),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: consts.ok.localize(), style: .cancel) { _ in})
    self.present(alert, animated: true, completion: nil)
  }

}

private let consts = (
  title : "Error",
  message : "Failed to reload data!",
  ok : "OK"
)

