//
//  Type.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct UsedType {
  let type: Type

  fileprivate init(type: Type) {
    self.type = type
  }
}

struct Type: UsedTypesProvider, CustomStringConvertible, Hashable {
  static let _Void = Type(module: .stdLib, name: "void ")
  static let _Any = Type(module: .stdLib, name: "id ")
  static let _AnyObject = Type(module: .stdLib, name: "id ")
  static let _String = Type(module: .stdLib, name: "NSString *")
  static let _Int = Type(module: .stdLib, name: "int ")
  static let _UInt = Type(module: .stdLib, name: "uint ")
  static let _Double = Type(module: .stdLib, name: "double ")
  static let _Character = Type(module: .stdLib, name: "char ")
  static let _CStringPointer = Type(module: .stdLib, name: "char *")
  static let _VoidPointer = Type(module: .stdLib, name: "id ")
  static let _URL = Type(module: "Foundation", name: "NSURL *")
  static let _Bundle = Type(module: "Foundation", name: "NSBundle *")
  static let _Locale = Type(module: "Foundation", name: "NSLocale *")
  static let _UINib = Type(module: "UIKit", name: "UINib *")
  static let _UIView = Type(module: "UIKit", name: "UIView *")
  static let _UIImage = Type(module: "UIKit", name: "UIImage *")
  static let _UIStoryboard = Type(module: "UIKit", name: "UIStoryboard *")
  static let _UITableViewCell = Type(module: "UIKit", name: "UITableViewCell *")
  static let _UICollectionViewCell = Type(module: "UIKit", name: "UICollectionViewCell *")
  static let _UICollectionReusableView = Type(module: "UIKit", name: "UICollectionReusableView *")
  static let _UIStoryboardSegue = Type(module: "UIKit", name: "UIStoryboardSegue *")
  static let _UITraitCollection = Type(module: "UIKit", name: "UITraitCollection *")
  static let _UIImageRenderingMode = Type(module: "UIKit", name: "UIImageRenderingMode ")
  static let _UIViewController = Type(module: "UIKit", name: "UIViewController *")
  static let _UIFont = Type(module: "UIKit", name: "UIFont *")
  static let _UIColor = Type(module: "UIKit", name: "UIColor *")
  static let _CGFloat = Type(module: .stdLib, name: "CGFloat *")
  static let _CVarArgType = Type(module: .stdLib, name: "CVarArgType... ")

  static let ReuseIdentifier = Type(module: "Foundation", name: "ReuseIdentifier", genericArgs: [TypeVar(description: "T", usedTypes: [])])
  static let ReuseIdentifierType = Type(module: "Foundation", name: "ReuseIdentifierType")
  static let StoryboardResourceType = Type(module: "Foundation", name: "StoryboardResourceType")
  static let StoryboardResourceWithInitialControllerType = Type(module: "Foundation", name: "StoryboardResourceWithInitialControllerType")
  static let StoryboardViewControllerResource = Type(module: "Foundation", name: "StoryboardViewControllerResource")
  static let NibResourceType = Type(module: "Foundation", name: "NibResourceType")
  static let FileResource = Type(module: "Foundation", name: "FileResource")
  static let FontResource = Type(module: "Foundation", name: "FontResource")
  static let ColorResource = Type(module: "Foundation", name: "ColorResource")
  static let ImageResource = Type(module: "Foundation", name: "ImageResource")
  static let StringResource = Type(module: "Foundation", name: "StringResource")
  static let Strings = Type(module: "Foundation", name: "Strings")
  static let Validatable = Type(module: "Foundation", name: "Validatable")
  static let TypedStoryboardSegueInfo = Type(module: "Foundation", name: "TypedStoryboardSegueInfo", genericArgs: [TypeVar(description: "Segue", usedTypes: []), TypeVar(description: "Source", usedTypes: []), TypeVar(description: "Destination", usedTypes: [])])

  let module: Module
  let name: SwiftIdentifier
  let genericArgs: [TypeVar]
  let optional: Bool

  var usedTypes: [UsedType] {
    return [UsedType(type: self)] + genericArgs.flatMap(getUsedTypes)
  }

  var description: String {
    return TypePrinter(type: self).swiftCode
  }

  var hashValue: Int {
    return description.hashValue
  }

  init(module: Module, name: SwiftIdentifier, genericArgs: [TypeVar] = [], optional: Bool = false) {
    self.module = module
    self.name = name
    self.genericArgs = genericArgs
    self.optional = optional
  }

  init(module: Module, name: SwiftIdentifier, genericArgs: [Type], optional: Bool = false) {
    self.module = module
    self.name = name
    self.genericArgs = genericArgs.map(TypeVar.init)
    self.optional = optional
  }

  func asOptional() -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: true)
  }

  func asNonOptional() -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: false)
  }

  func withGenericArgs(_ genericArgs: [TypeVar]) -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: optional)
  }

  func withGenericArgs(_ genericArgs: [Type]) -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: optional)
  }
}

func ==(lhs: Type, rhs: Type) -> Bool {
  return (lhs.hashValue == rhs.hashValue)
}
