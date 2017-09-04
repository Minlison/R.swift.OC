//
//  StructGenerator.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 06-09-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

protocol StructGenerator {
  typealias Result = (externalStruct: Struct, internalStruct: Struct?)

  func generatedStructs(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Result
}

protocol ExternalOnlyStructGenerator: StructGenerator {
  func generatedStruct(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct
}

extension ExternalOnlyStructGenerator {
  func generatedStructs(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> StructGenerator.Result {
    return (
      generatedStruct(at: externalAccessLevel, prefix: prefix),
      nil
    )
  }
}
