//
//  util.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 12-12-14.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

// MARK: Array operations

extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }
}

// MARK: Sequence operations

extension Sequence {
  func grouped<Key: Hashable>(by keySelector: (Iterator.Element) -> Key) -> [Key : [Iterator.Element]] {
    var groupedBy = Dictionary<Key, [Iterator.Element]>()

    for element in self {
      let key = keySelector(element)
      if let group = groupedBy[key] {
        groupedBy[key] = group + [element]
      } else {
        groupedBy[key] = [element]
      }
    }

    return groupedBy
  }
}

extension Sequence where Iterator.Element : Sequence {
  func flatten() -> [Iterator.Element.Iterator.Element] {
    return flatMap { $0 }
  }
}

// MARK: String operations

extension String {
  var lowercaseFirstCharacter: String {
    if self.characters.count <= 1 { return self.lowercased() }
    let index = characters.index(startIndex, offsetBy: 1)
    return substring(to: index).lowercased() + substring(from: index)
  }

  var uppercaseFirstCharacter: String {
    if self.characters.count <= 1 { return self.uppercased() }
    let index = characters.index(startIndex, offsetBy: 1)
    return substring(to: index).uppercased() + substring(from: index)
  }

  func indent(with indentation: String) -> String {
    let components = self.components(separatedBy: "\n")
    return indentation + components.joined(separator: "\n\(indentation)")
  }

  var fullRange: NSRange {
    return NSRange(location: 0, length: characters.count)
  }

  var escapedStringLiteral: String {
    return self
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\t", with: "\\t")
      .replacingOccurrences(of: "\r", with: "\\r")
      .replacingOccurrences(of: "\n", with: "\\n")
  }

  var commentString: String {
    return self
      .replacingOccurrences(of: "\r\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
      .replacingOccurrences(of: "\n", with: " ")
  }
}

// MARK: URL operations 

extension URL {
  var filename: String? {
    let filename = deletingPathExtension().lastPathComponent
    return filename.characters.count == 0 ? nil : filename
  }
}
