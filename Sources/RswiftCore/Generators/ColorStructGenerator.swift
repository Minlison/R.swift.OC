//
//  ColorStructGenerator.swift
//  R.swift
//
//  Created by Tom Lokhorst on 2016-03-13.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation
import AppKit.NSColor

struct ColorStructGenerator: ExternalOnlyStructGenerator {
  private let palettes: [ColorPalette]

  init(colorPalettes palettes: [ColorPalette]) {
    self.palettes = palettes
  }

  func generatedStruct(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct {
    let structName: SwiftIdentifier = "color"
    let qualifiedName = prefix + structName
    let groupedPalettes = palettes.groupedBySwiftIdentifier { $0.filename }
    groupedPalettes.printWarningsForDuplicatesAndEmpties(source: "color palette", result: "file")

    return Struct(
      comments: ["This `\(qualifiedName)` struct is generated, and contains static references to \(palettes.count) color palettes."],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: structName).asClass(className: "UIColor").asPointer(),
      implements: [],
      typealiasses: [],
      properties: [],
      functions: [],
      structs: groupedPalettes.uniques.flatMap { colorStruct(from: $0, at: externalAccessLevel, prefix: qualifiedName) },
      classes: []
    )
  }

  private func colorStruct(from palette: ColorPalette, at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct? {
    if palette.colors.isEmpty { return nil }

    let structName = SwiftIdentifier(name: palette.filename)
    let qualifiedName = prefix + structName
    let groupedColors = palette.colors.groupedBySwiftIdentifier { $0.0 }

    groupedColors.printWarningsForDuplicatesAndEmpties(source: "color", container: "in palette '\(palette.filename)'", result: "color")

    return Struct(
      comments: ["This `\(qualifiedName)` struct is generated, and contains static references to \(groupedColors.uniques.count) colors."],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: structName).asClass(className: "UIColor").asPointer(),
      implements: [],
      typealiasses: [],
      properties: groupedColors.uniques.map { arg in
        let (name, color) = arg
        return colorLet(name, color: color, at: externalAccessLevel)
      },
      functions: groupedColors.uniques.map { arg in
        let (name, color) = arg
        return colorFunction(name, color: color, at: externalAccessLevel)
      },
      structs: [],
      classes: []
    )
  }

  private func colorLet(_ name: String, color: NSColor, at externalAccessLevel: AccessLevel) -> Let {
    return Let(
      comments: [
        "<span style='background-color: #\(color.hexString); color: #\(color.opposite.hexString); padding: 1px 3px;'>#\(color.hexString)</span> \(name)"
      ],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: name),
      typeDefinition: .inferred(Type.ColorResource),
      value: "+ (UIColor *)\(SwiftIdentifier(name: name));"
    )
  }

  private func colorFunction(_ name: String, color: NSColor, at externalAccessLevel: AccessLevel) -> Function {
    return Function(
      comments: [
        "<span style='background-color: #\(color.hexString); color: #\(color.opposite.hexString); padding: 1px 3px;'>#\(color.hexString)</span> \(name)",
        "",
        "[UIColor colorWithRed:\(color.redComponent) green:\(color.greenComponent) blue:\(color.blueComponent) alpha:\(color.alphaComponent)];"
      ],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: name),
      generics: nil,
      parameters: [],
      doesThrow: false,
      returnType: Type._UIColor.asClass(className: "UIColor").asPointer(),
      body: "return [UIColor colorWithRed:\(color.redComponent) green:\(color.greenComponent) blue:\(color.blueComponent) alpha:\(color.alphaComponent)];"
    )
  }
}

private extension NSColor {
  var hexString: String {
    let red = UInt(roundf(Float(redComponent) * 255.0))
    let green = UInt(roundf(Float(greenComponent) * 255.0))
    let blue = UInt(roundf(Float(blueComponent) * 255.0))
    let alpha = UInt(roundf(Float(alphaComponent) * 255.0))

    if alphaComponent == 1 {
      let hex = (red << 16) | (green << 8) | (blue)

      return String(format:"%06X", hex)
    }
    else {
      let hex = (red << 24) | (green << 16) | (blue << 8) | (alpha)

      return String(format:"%08X", hex)
    }
  }

  var opposite: NSColor {
    return NSColor.init(calibratedRed: 1 - redComponent, green: 1 - greenComponent, blue: 1 - blueComponent, alpha: 1)
  }
}
