//
//  Xcodeproj.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 09-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation
import XcodeEdit

struct Xcodeproj: WhiteListedExtensionsResourceType {
  static let supportedExtensions: Set<String> = ["xcodeproj"]

  private let projectFile: XCProjectFile

  init(url: URL) throws {
    try Xcodeproj.throwIfUnsupportedExtension(url.pathExtension)

    // Parse project file
    guard let projectFile = try? XCProjectFile(xcodeprojURL: url) else {
      throw ResourceParsingError.parsingFailed("Project file at '\(url)' could not be parsed, is this a valid Xcode project file ending in *.xcodeproj?")
    }

    self.projectFile = projectFile
  }

  func resourcePathsForTarget(_ targetName: String) throws -> [Path] {
    // Look for target in project file
    let allTargets = projectFile.project.targets
    guard let target = allTargets.filter({ $0.name == targetName }).first else {
      let availableTargets = allTargets.map { $0.name }.joined(separator: ", ")
      throw ResourceParsingError.parsingFailed("Target '\(targetName)' not found in project file, available targets are: \(availableTargets)")
    }

    let resourcesFileRefs = target.buildPhases
      .flatMap { $0 as? PBXResourcesBuildPhase }
      .flatMap { $0.files }
      .map { $0.fileRef }

    let fileRefPaths = resourcesFileRefs
      .flatMap { $0 as? PBXFileReference }
      .map { $0.fullPath }

    let variantGroupPaths = resourcesFileRefs
      .flatMap { $0 as? PBXVariantGroup }
      .flatMap { $0.fileRefs }
      .map { $0.fullPath }

    return fileRefPaths + variantGroupPaths
  }
}
