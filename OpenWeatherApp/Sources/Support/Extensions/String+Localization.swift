//
//  String+Localization.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

extension String {
  /**
   Simplify localization
   */
  func localize() -> String {
    return NSLocalizedString(self, comment: "")
  }
}
