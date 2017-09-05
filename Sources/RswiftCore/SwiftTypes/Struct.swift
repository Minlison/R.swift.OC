//
//  Struct.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct Struct: UsedTypesProvider, SwiftCodeConverible {
  let comments: [String]
  let accessModifier: AccessLevel
  let type: Type
  var implements: [TypePrinter]
  let typealiasses: [Typealias]
  var properties: [Let]
  var functions: [Function]
  var structs: [Struct]
  var classes: [Class]

  var usedTypes: [UsedType] {
    return [
        type.usedTypes,
        implements.flatMap(getUsedTypes),
        typealiasses.flatMap(getUsedTypes),
        properties.flatMap(getUsedTypes),
        functions.flatMap(getUsedTypes),
        structs.flatMap(getUsedTypes),
      ].flatten()
  }

  var swiftCode: String {
    let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
    let accessModifierString = accessModifier.swiftCode
    let implementsString = implements.count > 0 ? ": " + implements.map { $0.swiftCode }.joined(separator: ", ") : ""

    let typealiasString = typealiasses
      .sorted { $0.alias < $1.alias }
      .map { $0.description }
      .joined(separator: "\n")

    let varsString = properties
      .map { $0.swiftCode }
      .sorted()
      .map { $0.description }
      .joined(separator: "\n")

    let functionsString = functions
      .map { $0.swiftCode }
      .sorted()
      .map { $0.description }
      .joined(separator: "\n\n")
    
    let structsString = structs
      .map { $0.swiftCode }
      .sorted()
      .map { $0.description }
      .joined(separator: "\n\n")

    let classesString = classes
      .map { $0.swiftCode }
      .sorted()
      .map { $0.description }
      .joined(separator: "\n\n")

    // File private `init`, so that struct can't be initialized from the outside world
    let fileprivateInit = "fileprivate init() {}"

    let bodyComponents = [typealiasString, varsString, functionsString, structsString, classesString, fileprivateInit].filter { $0 != "" }
    let bodyString = bodyComponents.joined(separator: "\n\n").indent(with: "  ")

    return "\(commentsString)\(accessModifierString)struct \(type)\(implementsString) {\n\(bodyString)\n}"
  }
    
    var ocImp: String {
        let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
//        let implementsString = implements.count > 0 ? ": " + implements.map { $0.swiftCode }.joined(separator: ", ") : ""
        
        
        let functionsString = functions
            .map { $0.ocImp }
            .sorted()
            .map { $0.description }
            .joined(separator: "\n\n")
        
        let structsString = structs
            .map { $0.ocImp }
            .sorted()
            .map { $0.description }
            .joined(separator: "\n\n")
        
        let categoryString = type.asNoPointer().description.uppercaseFirstCharacter + structs
            .map { $0.type.asNoPointer().description.uppercaseFirstCharacter }
            .joined(separator: "_")
        
        if functions.count <= 0 && structs.count <= 0 {
            return "/// no func and structs"
        }
        
        if !structsString.isEmpty {
            return "\(structsString)"
        }
        
        return "\(commentsString)@implementation \(type.className) (\(categoryString)) \n\(functionsString)\n@end\n\n"
    }
    var ocHeader: String {
        let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
//        let implementsString = implements.count > 0 ? ": " + implements.map { $0.swiftCode }.joined(separator: ", ") : ""
        
        let functionsString = functions
            .map { $0.ocHeader }
            .sorted()
            .map { $0.description }
            .joined(separator: "\n\n")
        
        let structsString = structs
            .map { $0.ocHeader }
            .sorted()
            .map { $0.description }
            .joined(separator: "\n\n")
        let categoryString = type.asNoPointer().name.description.uppercaseFirstCharacter + structs
            .map { $0.type.name.description.uppercaseFirstCharacter }
            .joined(separator: "_")
//        let bodyComponents = [functionsString].filter { $0 != "" }
//        let bodyString = bodyComponents.joined(separator: "\n\n").indent(with: "")
        
        if functions.count <= 0 && structs.count <= 0 {
            return "/// no func and structs"
        }
        
        if !structsString.isEmpty {
            return "\(structsString)"
        }
        
        
        return "\(commentsString)\n@interface \(type.className) (\(categoryString)) \n\(functionsString)\n@end\n\n"
    }
}
