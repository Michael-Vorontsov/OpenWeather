//
//  String+HTTPParameters.swift
//  OpenWeatherApp
//
//  Created by Mykhailo Vorontsov on 6/27/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

extension Dictionary {
  
  /**
   Simple extension to convert dictionary of oarameters into
   http parameters string.
   */
  func encodeToGetParameters() -> String {
    var parametersString = ""
    let generalDelimitersToEncode = consts.generalDelimitersToEncode
    let subDelimitersToEncode = consts.subDelimitersToEncode
    
    let allowedCharacterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
    allowedCharacterSet.removeCharacters(in: generalDelimitersToEncode + subDelimitersToEncode)
    
    for (key, value) in self {
      parametersString += parametersString.characters.count > 0 ? "&" : ""
      if let formattedKey = String(describing: key).addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet),

        let formattedValue = String(describing: value).addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) {
        
        parametersString += "\(formattedKey)=\(formattedValue)"
      }
    }
    return parametersString
  }
  
}

private let consts = (
  generalDelimitersToEncode : ":#[]@", // does not include "?" or "/" due to RFC 3986 - Section 3.4
  subDelimitersToEncode : "!$&'()*+,;="
)

