//
//  SegueStructGenerator.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

typealias SegueWithInfo = (segue: Storyboard.Segue, sourceType: Type, destinationType: Type)

struct SegueStructGenerator: ExternalOnlyStructGenerator {
  private let storyboards: [Storyboard]

  init(storyboards: [Storyboard]) {
    self.storyboards = storyboards
  }

  func generatedStruct(at externalAccessLevel: AccessLevel) -> Struct {
    let seguesWithInfo = storyboards.flatMap { storyboard in
      storyboard.viewControllers.flatMap { viewController in
        viewController.segues.flatMap { segue -> SegueWithInfo? in
          guard let destinationType = resolveDestinationTypeForSegue(
            segue,
            inViewController: viewController,
            inStoryboard: storyboard,
            allStoryboards: storyboards)
            else
          {
            warn("Destination view controller with id \(segue.destination) for segue \(segue.identifier) in \(viewController.type) not found in storyboard \(storyboard.name). Is this storyboard corrupt?")
            return nil
          }

          return (segue: segue, sourceType: viewController.type, destinationType: destinationType)
        }
      }
    }

    let deduplicatedSeguesWithInfo = seguesWithInfo
      .grouped { segue, sourceType, destinationType in
        "\(segue.identifier)|\(segue.type)|\(sourceType)|\(destinationType)"
      }
      .values
      .flatMap { $0.first }

    var structs: [Struct] = []

    for (sourceType, seguesBySourceType) in deduplicatedSeguesWithInfo.grouped(by: { $0.sourceType }) {
      let groupedSeguesWithInfo = seguesBySourceType.groupedBySwiftIdentifier { $0.segue.identifier }

      groupedSeguesWithInfo.printWarningsForDuplicatesAndEmpties(source: "segue", container: "for '\(sourceType)'", result: "segue")

      let sts = groupedSeguesWithInfo
        .uniques
        .grouped { $0.sourceType }
        .values
        .flatMap { self.seguesWithInfoForSourceTypeToStruct($0, at: externalAccessLevel) }

      structs = structs + sts
    }

    return Struct(
      comments: ["This `R.segue` struct is generated, and contains static references to \(structs.count) view controllers."],
      accessModifier: externalAccessLevel,
      type: Type(module: .host, name: "segue"),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: [],
      classes: []
    )
  }

  private func resolveDestinationTypeForSegue(_ segue: Storyboard.Segue, inViewController: Storyboard.ViewController, inStoryboard storyboard: Storyboard, allStoryboards storyboards: [Storyboard]) -> Type? {
    if segue.kind == "unwind" {
      return Type._UIViewController
    }

    let destinationViewControllerType = storyboard.viewControllers
      .filter { $0.id == segue.destination }
      .first?
      .type

    let destinationViewControllerPlaceholderType = storyboard.viewControllerPlaceholders
      .filter { $0.id == segue.destination }
      .first
      .flatMap { storyboard -> Type? in
        switch storyboard.resolveWithStoryboards(storyboards) {
        case .customBundle:
          return Type._UIViewController // Not supported, fallback to UIViewController
        case let .resolved(vc):
          return vc?.type
        }
      }

    return destinationViewControllerType ?? destinationViewControllerPlaceholderType
  }

  private func seguesWithInfoForSourceTypeToStruct(_ seguesWithInfoForSourceType: [SegueWithInfo], at externalAccessLevel: AccessLevel) -> Struct? {
    guard let sourceType = seguesWithInfoForSourceType.first?.sourceType else { return nil }

    let properties = seguesWithInfoForSourceType.map { segueWithInfo -> Let in
      let type = Type(
        module: "Rswift",
        name: "StoryboardSegueIdentifier",
        genericArgs: [segueWithInfo.segue.type, segueWithInfo.sourceType, segueWithInfo.destinationType],
        optional: false
      )
      return Let(
        comments: ["Segue identifier `\(segueWithInfo.segue.identifier)`."],
        accessModifier: externalAccessLevel,
        isStatic: true,
        name: SwiftIdentifier(name: segueWithInfo.segue.identifier),
        typeDefinition: .specified(type),
        value: "Rswift.StoryboardSegueIdentifier(identifier: \"\(segueWithInfo.segue.identifier)\")"
      )
    }

    let functions = seguesWithInfoForSourceType.map { segueWithInfo -> Function in
      Function(
        comments: [
          "Optionally returns a typed version of segue `\(segueWithInfo.segue.identifier)`.",
          "Returns nil if either the segue identifier, the source, destination, or segue types don't match.",
          "For use inside `prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)`."
        ],
        accessModifier: externalAccessLevel,
        isStatic: true,
        name: SwiftIdentifier(name: segueWithInfo.segue.identifier),
        generics: nil,
        parameters: [
          Function.Parameter.init(name: "segue", type: Type._UIStoryboardSegue)
        ],
        doesThrow: false,
        returnType: Type.TypedStoryboardSegueInfo
          .asOptional()
          .withGenericArgs([segueWithInfo.segue.type, segueWithInfo.sourceType, segueWithInfo.destinationType]),
        body: "return Rswift.TypedStoryboardSegueInfo(segueIdentifier: R.segue.\(SwiftIdentifier(name: sourceType.description)).\(SwiftIdentifier(name: segueWithInfo.segue.identifier)), segue: segue)"
      )
    }

    let typeName = SwiftIdentifier(name: sourceType.description)

    return Struct(
      comments: ["This struct is generated for `\(sourceType.name)`, and contains static references to \(properties.count) segues."],
      accessModifier: externalAccessLevel,
      type: Type(module: .host, name: typeName),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: [],
      classes: []
    )
  }
}

