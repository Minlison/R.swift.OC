//
//  StringsStructGenerator.swift
//  R.swift
//
//  Created by Nolan Warner on 2016/02/23.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct StringsStructGenerator: ExternalOnlyStructGenerator {
  private let localizableStrings: [LocalizableStrings]

  init(localizableStrings: [LocalizableStrings]) {
    self.localizableStrings = localizableStrings
  }

  func generatedStruct(at externalAccessLevel: AccessLevel) -> Struct {
    let localized = localizableStrings.grouped { $0.filename }
    let groupedLocalized = localized.groupedBySwiftIdentifier { $0.0 }

    groupedLocalized.printWarningsForDuplicatesAndEmpties(source: "strings file", result: "file")

    return Struct(
      comments: ["This `R.string` struct is generated, and contains static references to \(groupedLocalized.uniques.count) localization tables."],
      accessModifier: externalAccessLevel,
      type: Type(module: .host, name: "string"),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: groupedLocalized.uniques.flatMap { stringStructFromLocalizableStrings(filename: $0.0, strings: $0.1, at: externalAccessLevel) },
      classes: []
    )
  }

  private func stringStructFromLocalizableStrings(filename: String, strings: [LocalizableStrings], at externalAccessLevel: AccessLevel) -> Struct? {

    let name = SwiftIdentifier(name: filename)
    let params = computeParams(filename: filename, strings: strings)

    return Struct(
      comments: ["This `R.string.\(name)` struct is generated, and contains static references to \(params.count) localization keys."],
      accessModifier: externalAccessLevel,
      type: Type(module: .host, name: name),
      implements: [],
      typealiasses: [],
      properties: params.map { stringLet(values: $0, at: externalAccessLevel) },
      functions: params.map { stringFunction(values: $0, at: externalAccessLevel) },
      structs: [],
      classes: []
    )
  }

  // Ahem, this code is a bit of a mess. It might need cleaning up... ;-)
  // Maybe when we pick up this issue: https://github.com/mac-cain13/R.swift/issues/136
  private func computeParams(filename: String, strings: [LocalizableStrings]) -> [StringValues] {

    var allParams: [String: [(Locale, String, [StringParam])]] = [:]
    let baseKeys: Set<String>?
    let bases = strings.filter { $0.locale.isBase }
    if bases.isEmpty {
      baseKeys = nil
    }
    else {
      baseKeys = Set(bases.flatMap { $0.dictionary.keys })
    }

    // Warnings about duplicates and empties
    for ls in strings {
      let filenameLocale = ls.locale.withFilename(filename)
      let groupedKeys = ls.dictionary.keys.groupedBySwiftIdentifier { $0 }

      groupedKeys.printWarningsForDuplicatesAndEmpties(source: "string", container: "in \(filenameLocale)", result: "key")

      // Save uniques
      for key in groupedKeys.uniques {
        if let (params, commentValue) = ls.dictionary[key] {
          if let _ = allParams[key] {
            allParams[key]?.append((ls.locale, commentValue, params))
          }
          else {
            allParams[key] = [(ls.locale, commentValue, params)]
          }
        }
      }
    }

    // Warnings about missing translations
    for (locale, lss) in strings.grouped(by: { $0.locale }) {
      let filenameLocale = locale.withFilename(filename)
      let sourceKeys = baseKeys ?? Set(allParams.keys)

      let missing = sourceKeys.subtracting(lss.flatMap { $0.dictionary.keys })

      if missing.isEmpty {
        continue
      }

      let paddedKeys = missing.sorted().map { "'\($0)'" }
      let paddedKeysString = paddedKeys.joined(separator: ", ")

      warn("Strings file \(filenameLocale) is missing translations for keys: \(paddedKeysString)")
    }

    // Only include translation if it exists in Base
    func includeTranslation(_ key: String) -> Bool {
      if let baseKeys = baseKeys {
        return baseKeys.contains(key)
      }

      return true
    }

    var results: [StringValues] = []
    var badFormatSpecifiersKeys = Set<String>()

    // Unify format specifiers
    for (key, keyParams) in allParams.filter({ includeTranslation($0.0) }).sorted(by: { $0.0 < $1.0 }) {
      var params: [StringParam] = []
      var areCorrectFormatSpecifiers = true

      for (locale, _, ps) in keyParams {
        if ps.contains(where: { $0.spec == FormatSpecifier.topType }) {
          let name = locale.withFilename(filename)
          warn("Skipping string \(key) in \(name), not all format specifiers are consecutive")

          areCorrectFormatSpecifiers = false
        }
      }

      if !areCorrectFormatSpecifiers { continue }

      for (_, _, ps) in keyParams {
        if let unified = params.unify(ps) {
          params = unified
        }
        else {
          badFormatSpecifiersKeys.insert(key)

          areCorrectFormatSpecifiers = false
        }
      }

      if !areCorrectFormatSpecifiers { continue }

      let vals = keyParams.map { ($0.0, $0.1) }
      let values = StringValues(key: key, params: params, tableName: filename, values: vals )
      results.append(values)
    }

    for badKey in badFormatSpecifiersKeys.sorted() {
      let fewParams = allParams.filter { $0.0 == badKey }.map { $0.1 }

      if let params = fewParams.first {
        let locales = params.flatMap { $0.0.localeDescription }.joined(separator: ", ")
        warn("Skipping string for key \(badKey) (\(filename)), format specifiers don't match for all locales: \(locales)")
      }
    }

    return results
  }

  private func stringLet(values: StringValues, at externalAccessLevel: AccessLevel) -> Let {
    let escapedKey = values.key.escapedStringLiteral
    let locales = values.values
      .map { $0.0 }
      .flatMap { $0.localeDescription }
      .map { "\"\($0)\"" }
      .joined(separator: ", ")

    return Let(
      comments: values.comments,
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: values.key),
      typeDefinition: .inferred(Type.StringResource),
      value: "@\"\(escapedKey)\""
    )
  }

  private func stringFunction(values: StringValues, at externalAccessLevel: AccessLevel) -> Function {
    if values.params.isEmpty {
      return stringFunctionNoParams(for: values, at: externalAccessLevel)
    }
    else {
      return stringFunctionParams(for: values, at: externalAccessLevel)
    }
  }

  private func stringFunctionNoParams(for values: StringValues, at externalAccessLevel: AccessLevel) -> Function {

    return Function(
      comments: values.comments,
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: values.key),
      generics: nil,
      parameters: [
        Function.Parameter(name: "_", type: Type._Void, defaultValue: "()")
      ],
      doesThrow: false,
      returnType: Type._String,
      body: "return \(values.localizedString);"
    )
  }

  private func stringFunctionParams(for values: StringValues, at externalAccessLevel: AccessLevel) -> Function {

    let params = values.params.enumerated().map { ix, param -> Function.Parameter in
      let argumentLabel = param.name ?? "_"
      let valueName = "value\(ix + 1)"

      return Function.Parameter(name: argumentLabel, localName: valueName, type: param.spec.type)
    }

    let args = params.map { $0.localName ?? $0.name }.joined(separator: ", ")

    return Function(
      comments: values.comments,
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: values.key),
      generics: nil,
      parameters: params,
      doesThrow: false,
      returnType: Type._String,
//      body: "return String(format: \(values.localizedString), locale: R.applicationLocale, \(args))"
      body: "return [NSString localizedStringWithFormat:\(values.localizedString),\(args)];"
    )
  }

}

extension Locale {
  func withFilename(_ filename: String) -> String {
    switch self {
    case .none:
      return "'\(filename)'"
    case .base:
      return "'\(filename)' (Base)"
    case .language(let language):
      return "'\(filename)' (\(language))"
    }
  }
}

private struct StringValues {
  let key: String
  let params: [StringParam]
  let tableName: String
  let values: [(Locale, String)]

  var localizedString: String {
    let escapedKey = key.escapedStringLiteral

    if tableName == "Localizable" {
//      return "NSLocalizedString(\"\(escapedKey)\", bundle: R.hostingBundle, comment: \"\")"
      return "NSLocalizedString(@\"\(escapedKey)\", @\"\")"
    }
    else {
//      return "NSLocalizedString(\"\(escapedKey)\", tableName: \"\(tableName)\", bundle: R.hostingBundle, comment: \"\")"
      return "NSLocalizedStringFromTable(@\"\(escapedKey)\", nil, @\"\(tableName)\")"
    }
  }

  var comments: [String] {
    var results: [String] = []

    let containsBase = values.contains { $0.0.isBase }
    let baseValue = values.filter { $0.0.isBase }.map { $0.1 }.first
    let anyNone = values.contains { $0.0.isNone }

    if let baseValue = baseValue {
      let str = "Base translation: \(baseValue)".commentString
      results.append(str)
    }
    else if !containsBase {
      if let (locale, value) = values.first {
        if let localeDescription = locale.localeDescription {
          let str = "\(localeDescription) translation: \(value)".commentString
          results.append(str)
        }
        else {
          let str = "Value: \(value)".commentString
          results.append(str)
        }
      }
    }

    if !anyNone {
      if !results.isEmpty {
        results.append("")
      }

      let locales = values.flatMap { $0.0.localeDescription }
      results.append("Locales: \(locales.joined(separator: ", "))")
    }

    return results
  }
}
