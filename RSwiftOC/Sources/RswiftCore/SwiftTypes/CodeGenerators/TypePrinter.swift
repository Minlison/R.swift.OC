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
    let optionalString = ""

    let withoutModule: String
    if type.genericArgs.count > 0 {
      let args = type.genericArgs.map { $0.description }.joined(separator: ", ")
      withoutModule = "\(type.name)<\(args)>"
    } else {
      withoutModule = "\(type.name)"
    }

    return "\(type.name)"
  }

  init(type: Type) {
    self.type = type
  }
}

