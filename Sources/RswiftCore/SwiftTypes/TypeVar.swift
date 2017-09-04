//
//  TypeVar.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 22-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct TypeVar: UsedTypesProvider, CustomStringConvertible {
  let description: String
  let usedTypes: [UsedType]

  init(type: Type) {
    assert(type.genericArgs.count == 0, "TypeVars may not have generic args")

    description = type.description
    usedTypes = [type]
      .map { $0.withGenericArgs([] as [TypeVar]) } // Defensively handle if there are generic types
      .flatMap(getUsedTypes)
  }

  init(description: String, usedTypes: [Type]) {
    assert(usedTypes.flatMap { $0.genericArgs }.count == 0, "TypeVars may not have generic args")

    self.description = description
    self.usedTypes = usedTypes
      .map { $0.withGenericArgs([] as [TypeVar]) } // Defensively handle if there are generic types
      .flatMap(getUsedTypes)
  }
}
