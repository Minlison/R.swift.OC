//
//  Resources.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 08-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

enum ResourceParsingError: Error {
  case unsupportedExtension(givenExtension: String?, supportedExtensions: Set<String>)
  case parsingFailed(String)
}

struct Resources {
  let assetFolders: [AssetFolder]
  let images: [Image]
  let colors: [ColorPalette]
  let fonts: [Font]
  let nibs: [Nib]
  let storyboards: [Storyboard]
  let resourceFiles: [ResourceFile]
  let localizableStrings: [LocalizableStrings]
    
  let reusables: [Reusable]

  init(resourceURLs: [URL], fileManager: FileManager) {
    assetFolders = resourceURLs.flatMap { url in tryResourceParsing { try AssetFolder(url: url, fileManager: fileManager) } }
    images = resourceURLs.flatMap { url in tryResourceParsing { try Image(url: url) } }
    colors = resourceURLs.flatMap { url in tryResourceParsing { try ColorPalette(url: url) } }
    fonts = resourceURLs.flatMap { url in tryResourceParsing { try Font(url: url) } }
    nibs = resourceURLs.flatMap { url in tryResourceParsing { try Nib(url: url) } }
    storyboards = resourceURLs.flatMap { url in tryResourceParsing { try Storyboard(url: url) } }
    resourceFiles = resourceURLs.flatMap { url in tryResourceParsing { try ResourceFile(url: url) } }
    reusables = (nibs.map { $0 as ReusableContainer } + storyboards.map { $0 as ReusableContainer })
      .flatMap { $0.reusables }
    localizableStrings = resourceURLs.flatMap { url in tryResourceParsing { try LocalizableStrings(url: url) } }
  }
}

private func tryResourceParsing<T>(_ parse: () throws -> T) -> T? {
  do {
    return try parse()
  } catch let ResourceParsingError.parsingFailed(humanReadableError) {
    warn(humanReadableError)
    return nil
  } catch ResourceParsingError.unsupportedExtension {
    return nil
  } catch {
    return nil
  }
}
