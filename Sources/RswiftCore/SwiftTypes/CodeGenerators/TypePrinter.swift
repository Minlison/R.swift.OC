//
//  TypePrinter.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 14-01-16.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct TypePrinter: SwiftCodeConverible, UsedTypesProvider {
  let type: Type

  var usedTypes: [UsedType] {
    return type.usedTypes
  }

  var swiftCode: String {
    if type.isPointer {
            return "\(type.name) *"
    }
    return "\(type.name)"
    
  }
    var ocHeader: String{
        return swiftCode
    }
    var ocImp: String {
        return swiftCode
    }

  init(type: Type) {
    self.type = type
  }
}

