//
//  ImportPrinter.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 06-10-16.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

/// Prints all import statements for the modules used in the given structs
struct ImportPrinter: SwiftCodeConverible {
    let swiftCode: String
    let ocHeader : String
    let ocImp: String
  init(modules: Set<Module>, extractFrom structs: [Struct?], exclude excludedModules: Set<Module>) {
    let extractedModules = structs
      .flatMap { $0 }
      .flatMap(getUsedTypes)
      .map { $0.type.module }
    
    swiftCode = modules
        .union(extractedModules)
        .subtracting(excludedModules)
        .sorted { $0.description < $1.description }.map({ (m:Module) -> String in
            if m.isCustom {
                return "#import \"\(m.description).h\""
            }
            return "#import <\(m.description)/\(m.description).h>"
        }).joined(separator: "\n")
    
    
//    swiftCode = modules
//      .union(extractedModules)
//      .subtracting(excludedModules)
////      .filter { $0.isCustom }
//      .sorted { $0.description < $1.description }
//      .map { "#import <\($0)/\($0).h>" }
//      .joined(separator: "\n")
    ocHeader = swiftCode
    ocImp = swiftCode
    
  }
}
