//
//  AggregatedStructGenerator.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 05-10-16.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

class AggregatedStructGenerator: StructGenerator {
  private let subgenerators: [StructGenerator]

  init(subgenerators: [StructGenerator]) {
    self.subgenerators = subgenerators
  }

  func generatedStructs(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> StructGenerator.Result {
    let structName: SwiftIdentifier = "R"
    let qualifiedName = structName
    let internalStructName: SwiftIdentifier = "_R"

    let collectedResult = subgenerators
      .map { $0.generatedStructs(at: externalAccessLevel, prefix: qualifiedName) }
      .reduce(StructGeneratorResultCollector()) { collector, result in collector.appending(result) }

    let externalStruct = Struct(
      comments: ["This `\(qualifiedName)` struct is generated and contains references to static resources."],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: structName),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: collectedResult.externalStructs,
      classes: []
    )

    let internalStruct = Struct(
      comments: [],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: internalStructName),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: collectedResult.internalStructs,
      classes: []
    )

    return (externalStruct, internalStruct)
  }
}

private struct StructGeneratorResultCollector {
  let externalStructs: [Struct]
  let internalStructs: [Struct]

  init() {
    self.externalStructs = []
    self.internalStructs = []
  }

  private init(externalStructs: [Struct], internalStructs: [Struct]) {
    self.externalStructs = externalStructs
    self.internalStructs = internalStructs
  }

  func appending(_ result: StructGenerator.Result) -> StructGeneratorResultCollector {
    return StructGeneratorResultCollector(
      externalStructs: externalStructs + [result.externalStruct],
      internalStructs: internalStructs + [result.internalStruct].flatMap { $0 }
    )
  }
}

