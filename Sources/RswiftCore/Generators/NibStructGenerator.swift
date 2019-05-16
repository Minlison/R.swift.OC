//
//  NibStructGenerator.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

private let Ordinals = [
  (number: 1, word: "first"),
  (number: 2, word: "second"),
  (number: 3, word: "third"),
  (number: 4, word: "fourth"),
  (number: 5, word: "fifth"),
  (number: 6, word: "sixth"),
  (number: 7, word: "seventh"),
  (number: 8, word: "eighth"),
  (number: 9, word: "ninth"),
  (number: 10, word: "tenth"),
  (number: 11, word: "eleventh"),
  (number: 12, word: "twelfth"),
  (number: 13, word: "thirteenth"),
  (number: 14, word: "fourteenth"),
  (number: 15, word: "fifteenth"),
  (number: 16, word: "sixteenth"),
  (number: 17, word: "seventeenth"),
  (number: 18, word: "eighteenth"),
  (number: 19, word: "nineteenth"),
  (number: 20, word: "twentieth"),
]

struct NibStructGenerator: StructGenerator {
  private let nibs: [Nib]

  init(nibs: [Nib]) {
    self.nibs = nibs
  }

  func generatedStructs(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> StructGenerator.Result {
    let structName: SwiftIdentifier = "nib"
    let qualifiedName = prefix + structName
    let groupedNibs = nibs.groupedBySwiftIdentifier { $0.name }
    groupedNibs.printWarningsForDuplicatesAndEmpties(source: "xib", result: "file")

    let internalStruct = Struct(
      comments: [],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: SwiftIdentifier(name:structName.orginalName  + "Internal")).asClass(className: "UINib"),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: groupedNibs
        .uniques
        .map { nibStruct(for: $0, at: externalAccessLevel) },
      classes: []
    )

    let nibProperties: [Let] = groupedNibs
      .uniques
      .map { nibVar(for: $0, at: externalAccessLevel, prefix: qualifiedName) }
    let nibFunctions: [Function] = groupedNibs
      .uniques
      .map { nibFunc(for: $0, at: externalAccessLevel, prefix: qualifiedName) }

    let externalStruct = Struct(
      comments: ["This R`\(qualifiedName)` struct is generated, and contains static references to \(nibProperties.count) nibs."],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: SwiftIdentifier(name:structName.orginalName  + "External")).asClass(className: "UINib"),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: nibFunctions,
      structs: [],
      classes: []
    )

    return (
      externalStruct,
      internalStruct
    )
  }

  private func nibFunc(for nib: Nib, at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Function {
//    let nibName = SwiftIdentifier(name: nib.name)
//    let qualifiedName = prefix + nibName

    return Function(
      comments: ["`[UINib nibWithNibName:@\"\(nib.name)\" bundle:nil]`"],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: nib.name),
      generics: nil,
      parameters: [],
      doesThrow: false,
      returnType: Type._UINib.asClass(className: "UINib"),
      body: "return [UINib nibWithNibName:@\"\(nib.name)\" bundle:nil];"
    )
  }

  private func nibVar(for nib: Nib, at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Let {
    let structName = SwiftIdentifier(name: "_\(nib.name)")
    let qualifiedName = prefix + structName
    let structType = Type(module: .uikit, name: SwiftIdentifier(rawValue: "_\(qualifiedName)"))
    return Let(
      comments: ["Nib `\(nib.name)`."],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: nib.name),
      typeDefinition: .inferred(structType),
      value: "+ (UINib *)\(nib.name)"
    )
  }

  private func nibStruct(for nib: Nib, at externalAccessLevel: AccessLevel) -> Struct {
    let instantiateParameters = [
        Function.Parameter(name: "ownerOrNil", localName: "ownerOrNil", type: Type._AnyObject.asOptional().asClass(className: "NSObject"), defaultValue: "nil"),
        Function.Parameter(name: "optionsOrNil", localName: "optionsOrNil", type: Type._DicObject.asOptional().asClass(className: "NSDictionary"), defaultValue: "nil")
    ]

    let viewFuncs = zip(nib.rootViews, Ordinals)
      .map { (view: $0.0, ordinal: $0.1) }
      .map { viewInfo -> Function in
        let viewIndex = viewInfo.ordinal.number - 1
//        let viewTypeString = viewInfo.view.description
        return Function(
          comments: [],
          accessModifier: externalAccessLevel,
          isStatic: false,
          name: SwiftIdentifier(name: "\(viewInfo.ordinal.word)View"),
          generics: nil,
          parameters: instantiateParameters,
          doesThrow: false,
          returnType: viewInfo.view.asOptional(),
          body: "return [[UINib alloc] instantiateWithOwner:ownerOrNil options:optionsOrNil][\(viewIndex)];" // as? \(viewTypeString)
        )
      }
    // Validation
//    let validateImagesLines = Set(nib.usedImageIdentifiers)
//      .map {
//        "if UIKit.UIImage(named: \"\($0)\", in: R.hostingBundle, compatibleWith: nil) == nil { throw Rswift.ValidationError(description: \"[R.swift] Image named '\($0)' is used in nib '\(nib.name)', but couldn't be loaded.\") }"
//    }

//    var validateFunctions: [Function] = []
//    var validateImplements: [Type] = []
//    if validateImagesLines.count > 0 {
//      let validateFunction = Function(
//        comments: [],
//        accessModifier: externalAccessLevel,
//        isStatic: true,
//        name: "validate",
//        generics: nil,
//        parameters: [],
//        doesThrow: true,
//        returnType: Type._Void,
//        body: validateImagesLines.joined(separator: "\n")
//      )
//      validateFunctions.append(validateFunction)
//      validateImplements.append(Type.Validatable)
//    }

    let sanitizedName = SwiftIdentifier(name: nib.name, lowercaseStartingCharacters: false)

    return Struct(
      comments: [],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: SwiftIdentifier(name: "_\(sanitizedName)")).asClass(className: "UINib"),
      implements: ([Type.NibResourceType]).map(TypePrinter.init),
      typealiasses: [],
      properties: [],
      functions: viewFuncs,
      structs: [],
      classes: []
    )
  }
}
