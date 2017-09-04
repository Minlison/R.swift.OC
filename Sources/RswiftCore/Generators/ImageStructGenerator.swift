//
//  ImageStructGenerator.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct ImageStructGenerator: ExternalOnlyStructGenerator {
  private let assetFolders: [AssetFolder]
  private let images: [Image]

  init(assetFolders: [AssetFolder], images: [Image]) {
    self.assetFolders = assetFolders
    self.images = images
  }

  func generatedStruct(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct {
    let structName: SwiftIdentifier = "image" // 更改文件名
    let qualifiedName = prefix + structName
    
    let assetFolderImageNames = assetFolders
      .flatMap { $0.imageAssets }

    let imagesNames = images
      .grouped { $0.name }
      .values
      .flatMap { $0.first?.name }

    let allFunctions = assetFolderImageNames + imagesNames
    let groupedFunctions = allFunctions.groupedBySwiftIdentifier { $0 }

    groupedFunctions.printWarningsForDuplicatesAndEmpties(source: "image", result: "image")


    let assetSubfolders = AssetSubfolders(
      all: assetFolders.flatMap { $0.subfolders },
      assetIdentifiers: allFunctions.map { SwiftIdentifier(name: $0) })

    assetSubfolders.printWarningsForDuplicates()

    let structs = assetSubfolders.folders
      .map { $0.generatedStruct(at: externalAccessLevel, prefix: qualifiedName) }

    let imageLets = groupedFunctions
      .uniques
      .map { name in
        Let(
          comments: ["Image `\(name)`."],
          accessModifier: externalAccessLevel,
          isStatic: true,
          name: SwiftIdentifier(name: name),
          typeDefinition: .inferred(Type.ImageResource),
          value: "+ (UIImage *)\(SwiftIdentifier(name: name));"
        )
    }

    return Struct(
      comments: ["This `R.image` struct is generated, and contains static references to \(imageLets.count) images."],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: structName).asClass(className: "UIImage").asPointer(),
      implements: [],
      typealiasses: [],
      properties: imageLets,
      functions: groupedFunctions.uniques.map { imageFunction(for: $0, at: externalAccessLevel) },
      structs: structs,
      classes: []
    )
  }

  private func imageFunction(for name: String, at externalAccessLevel: AccessLevel) -> Function {
    let param = Function.Parameter(
        name: "renderingMode",
        localName: "renderingMode",
        type: Type._UIImageRenderingMode.asClass(className: "UIImage").asOptional(),
        defaultValue: "UIImageRenderingModeAutomatic"
    )
    return Function(
      comments: ["`[[UIImage imageNamed:@\"\(SwiftIdentifier(name: name))\"] imageWithRenderingMode:\(param.name)]`"],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: name),
      generics: nil,
      parameters: [param],
      doesThrow: false,
      returnType: Type._UIImage.asClass(className: "UIImage"),
      body: "return [[UIImage imageNamed:@\"\(SwiftIdentifier(name: name))\"] imageWithRenderingMode:\(param.name)];"
    )
  }
}

extension NamespacedAssetSubfolder: ExternalOnlyStructGenerator {
  func generatedStruct(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct {
    let allFunctions = imageAssets
    let groupedFunctions = allFunctions.groupedBySwiftIdentifier { $0 }

    groupedFunctions.printWarningsForDuplicatesAndEmpties(source: "image", result: "image")


    let assetSubfolders = AssetSubfolders(
      all: subfolders,
      assetIdentifiers: allFunctions.map { SwiftIdentifier(name: $0) })

    assetSubfolders.printWarningsForDuplicates()

//    let imagePath = resourcePath + (!path.isEmpty ? "/" : "")
    let structName = SwiftIdentifier(name: self.name)
    let qualifiedName = prefix + structName
    let structPathName = qualifiedName.description.replacingOccurrences(of: ".", with: "_")
    
    let structs = assetSubfolders.folders
      .map { $0.generatedStruct(at: externalAccessLevel, prefix: qualifiedName) }

    let imageLets = groupedFunctions
      .uniques
      .map { name in
        Let(
          comments: ["`[UIImage imageNamed:\(name)\"]`"],
          accessModifier: externalAccessLevel,
          isStatic: true,
          name: SwiftIdentifier(name: name),
          typeDefinition: .inferred(Type.ImageResource),
          value: "+ (UIImage *)\(SwiftIdentifier(name: name));"
        )
    }

    return Struct(
      comments: ["This R`\(qualifiedName)` struct is generated, and contains static references to \(imageLets.count) images."],
      accessModifier: externalAccessLevel,
      type: Type(module: .uikit, name: SwiftIdentifier(name: structPathName)).asClass(className: "UIImage"),
      implements: [],
      typealiasses: [],
      properties: imageLets,
      functions: groupedFunctions.uniques.map { imageFunction(for: $0, at: externalAccessLevel) },
      structs: structs,
      classes: []
    )
  }

  private func imageFunction(for name: String, at externalAccessLevel: AccessLevel) -> Function {
    let param = Function.Parameter(
        name: "renderingMode",
        localName: "renderingMode",
        type: Type._UIImageRenderingMode.asClass(className: "UIImage").asOptional(),
        defaultValue: "UIImageRenderingModeAutomatic"
    )
    return Function(
      comments: ["return [[UIImage imageNamed:@\"\(SwiftIdentifier(name: name))\"] imageWithRenderingMode:\(param.name)];"],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: SwiftIdentifier(name: name),
      generics: nil,
      parameters: [param],
      doesThrow: false,
      returnType: Type._UIImage.asClass(className: "UIImage"),
      body: "return [[UIImage imageNamed:@\"\(SwiftIdentifier(name: name))\"] imageWithRenderingMode:\(param.name)];"
    )
  }
}

struct AssetSubfolders {
  let folders: [NamespacedAssetSubfolder]
  let duplicates: [NamespacedAssetSubfolder]

  init(all subfolders: [NamespacedAssetSubfolder], assetIdentifiers: [SwiftIdentifier]) {
    var dict: [SwiftIdentifier: NamespacedAssetSubfolder] = [:]

    for subfolder in subfolders {
      let name = SwiftIdentifier(name: subfolder.name)
      if let duplicate = dict[name] {
        duplicate.subfolders += subfolder.subfolders
        duplicate.imageAssets += subfolder.imageAssets
      } else {
        dict[name] = subfolder
      }
    }

    self.folders = dict.values.filter { !assetIdentifiers.contains(SwiftIdentifier(name: $0.name)) }
    self.duplicates = dict.values.filter { assetIdentifiers.contains(SwiftIdentifier(name: $0.name)) }
  }

  func printWarningsForDuplicates() {
    for subfolder in duplicates {
      warn("Skipping asset subfolder because symbol '\(subfolder.name)' would conflict with image: \(subfolder.name)")
    }
  }
}
