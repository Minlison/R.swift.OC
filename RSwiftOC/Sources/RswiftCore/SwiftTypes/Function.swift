//
//  Function.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct Function: UsedTypesProvider, SwiftCodeConverible {
  let comments: [String]
  let accessModifier: AccessLevel
  let isStatic: Bool
  let name: SwiftIdentifier
  let generics: String?
  let parameters: [Parameter]
  let doesThrow: Bool
  let returnType: Type
  let body: String

  init(comments: [String], accessModifier: AccessLevel, isStatic: Bool, name: SwiftIdentifier, generics: String?, parameters: [Parameter], doesThrow: Bool, returnType: Type, body: String) {
    self.comments = comments
    self.accessModifier = accessModifier
    self.isStatic = isStatic
    self.name = name
    self.generics = generics
    self.parameters = parameters
    self.doesThrow = doesThrow
    self.returnType = returnType
    self.body = body
  }

  var usedTypes: [UsedType] {
    return [
      returnType.usedTypes,
      parameters.flatMap(getUsedTypes),
    ].flatten()
  }

  var swiftCode: String {
    let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
    let accessModifierString = accessModifier.swiftCode
    let staticString = "static inline "
    let genericsString = generics.map { "<\($0)>" } ?? ""
    let parameterString = parameters.map { $0.description }.joined(separator: ", ")
    let throwString = doesThrow ? " throws" : ""
    let returnString = "\(returnType)"
    let bodyString = body.indent(with: "    ")

    return "\(commentsString)\(staticString) \(returnString)\(name)(\(parameterString)) {\n\(bodyString)\n}"
  }

  struct Parameter: UsedTypesProvider, CustomStringConvertible {
    let name: String
    let localName: String?
    let type: Type
    let defaultValue: String?

    var usedTypes: [UsedType] {
      return type.usedTypes
    }

    var swiftIdentifier: SwiftIdentifier {
      return SwiftIdentifier(name: name, lowercaseStartingCharacters: true)
    }

    var description: String {
      let definition = localName.map({ Type._Void == self.type ? "" : " \(self.type)\($0)" }) ?? ""

      return definition
//      return defaultValue.map({ "\(definition) = \($0)" }) ?? definition
    }

    init(name: String, type: Type, defaultValue: String? = nil) {
      self.name = name
      self.localName = nil
      self.type = type
      self.defaultValue = defaultValue
    }

    init(name: String, localName: String?, type: Type, defaultValue: String? = nil) {
      self.name = name
      self.localName = localName
      self.type = type
      self.defaultValue = defaultValue
    }
  }
}
