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
    static let _Void = Type(module: .foundation, name: "void").asNoPointer()
    static let _Any = Type(module: .foundation, name: "id").asNoPointer()
    static let _AnyObject = Type(module: .foundation, name: "id").asNoPointer()
    static let _DicObject = Type(module: .foundation, name: "NSDictionary")
    static let _String = Type(module: .foundation, name: "NSString")
    static let _Int = Type(module: .foundation, name: "int").asNoPointer()
    static let _UInt = Type(module: .foundation, name: "uint").asNoPointer()
    static let _Double = Type(module: .foundation, name: "double").asNoPointer()
    static let _Character = Type(module: .foundation, name: "char").asNoPointer()
    static let _CStringPointer = Type(module: .foundation, name: "char *").asNoPointer()
    static let _VoidPointer = Type(module: .foundation, name: "void *").asNoPointer()
    static let _URL = Type(module: .foundation, name: "NSURL")
    static let _Bundle = Type(module: .foundation, name: "NSBundle")
    static let _Locale = Type(module: .foundation, name: "NSLocale")
    static let _UINib = Type(module: .uikit, name: "UINib")
    static let _UIView = Type(module: .uikit, name: "UIView")
    static let _UIImage = Type(module: .uikit, name: "UIImage")
    static let _UIStoryboard = Type(module: .uikit, name: "UIStoryboard")
    static let _UITableViewCell = Type(module: .uikit, name: "UITableViewCell")
    static let _UICollectionViewCell = Type(module: .uikit, name: "UICollectionViewCell")
    static let _UICollectionReusableView = Type(module: .uikit, name: "UICollectionReusableView")
    static let _UIStoryboardSegue = Type(module: .uikit, name: "UIStoryboardSegue")
    static let _UITraitCollection = Type(module: .uikit, name: "UITraitCollection")
    static let _UIViewController = Type(module: .uikit, name: "UIViewController")
    static let _UIFont = Type(module: .uikit, name: "UIFont")
    static let _UIColor = Type(module: .uikit, name: "UIColor")
    static let _CGFloat = Type(module: .uikit, name: "CGFloat").asNoPointer()
    static let _CVarArgType = Type(module: .foundation, name: "CVarArgType...").asNoPointer()
    static let _UIImageRenderingMode = Type(module: .uikit, name: "UIImageRenderingMode").asNoPointer()
    static let _NSString = Type(module: .foundation, name: "NSString")
    
    static let ReuseIdentifier = Type(module: .foundation, name: "NSString", genericArgs: [TypeVar(description: "T", usedTypes: [])])
    static let ReuseIdentifierType = Type(module: .foundation, name: "NSString")
    static let StoryboardResourceType = Type(module: .foundation, name: "NSURL")
    static let StoryboardResourceWithInitialControllerType = Type(module: .uikit, name: "StoryboardResourceWithInitialControllerType")
    static let StoryboardViewControllerResource = Type(module: .uikit, name: "NSURL")
    static let NibResourceType = Type(module: .uikit, name: "NSURL")
    static let FileResource = Type(module: .uikit, name: "NSURL")
    static let FontResource = Type(module: .uikit, name: "NSURL")
    static let ColorResource = Type(module: .uikit, name: "NSURL")
    static let ImageResource = Type(module: .uikit, name: "NSURL")
    static let StringResource = Type(module: .uikit, name: "NSURL")
    static let Strings = Type(module: .uikit, name: "Strings")
    static let Validatable = Type(module: .uikit, name: "Validatable")
    static let TypedStoryboardSegueInfo = Type(module: .uikit, name: "TypedStoryboardSegueInfo", genericArgs: [TypeVar(description: "Segue", usedTypes: []), TypeVar(description: "Source", usedTypes: []), TypeVar(description: "Destination", usedTypes: [])])
    
//    static let ReuseIdentifier = Type(module: "Rswift", name: "ReuseIdentifier", genericArgs: [TypeVar(description: "T", usedTypes: [])])
//    static let ReuseIdentifierType = Type(module: "Rswift", name: "ReuseIdentifierType")
//    static let StoryboardResourceType = Type(module: "Rswift", name: "StoryboardResourceType")
//    static let StoryboardResourceWithInitialControllerType = Type(module: "Rswift", name: "StoryboardResourceWithInitialControllerType")
//    static let StoryboardViewControllerResource = Type(module: "Rswift", name: "StoryboardViewControllerResource")
//    static let NibResourceType = Type(module: "Rswift", name: "NibResourceType")
//    static let FileResource = Type(module: "Rswift", name: "FileResource")
//    static let FontResource = Type(module: "Rswift", name: "FontResource")
//    static let ColorResource = Type(module: "Rswift", name: "ColorResource")
//    static let ImageResource = Type(module: "Rswift", name: "ImageResource")
//    static let StringResource = Type(module: "Rswift", name: "StringResource")
//    static let Strings = Type(module: "Rswift", name: "Strings")
//    static let Validatable = Type(module: "Rswift", name: "Validatable")
//    static let TypedStoryboardSegueInfo = Type(module: "Rswift", name: "TypedStoryboardSegueInfo", genericArgs: [TypeVar(description: "Segue", usedTypes: []), TypeVar(description: "Source", usedTypes: []), TypeVar(description: "Destination", usedTypes: [])])
    
    let module: Module
    let name: SwiftIdentifier
    let className: SwiftIdentifier
    let genericArgs: [TypeVar]
    let optional: Bool
    
    let isPointer: Bool
    
    var usedTypes: [UsedType] {
        return [UsedType(type: self)] + genericArgs.flatMap(getUsedTypes)
    }
    
    var description: String {
        return TypePrinter(type: self).swiftCode
    }
    
    var hashValue: Int {
        return description.hashValue
    }
    
    
    init(module: Module, name: SwiftIdentifier, className: SwiftIdentifier? = nil, genericArgs: [TypeVar] = [], optional: Bool = false, pointer: Bool = true) {
        self.module = module
        self.name = name
        self.className = className ?? name;
        self.genericArgs = genericArgs
        self.optional = optional
        self.isPointer = pointer
    }
    
    init(module: Module, name: SwiftIdentifier, className: SwiftIdentifier? = nil, genericArgs: [Type], optional: Bool = false, pointer: Bool = true) {
        self.module = module
        self.name = name
        self.className = className ?? name;
        self.genericArgs = genericArgs.map(TypeVar.init)
        self.optional = optional
        self.isPointer = pointer
    }
    
    func asClass(className: SwiftIdentifier) -> Type {
        return Type(module: module, name: name,className:className, genericArgs: genericArgs, optional: optional, pointer: isPointer)
    }
    
    func asPointer() -> Type {
        return Type(module: module, name: name,className:className, genericArgs: genericArgs, optional: optional, pointer: true)
    }
    func asNoPointer() -> Type {
        return Type(module: module, name: name,className:className, genericArgs: genericArgs, optional: optional, pointer: false)
    }
    
    func asOptional() -> Type {
        return Type(module: module, name: name,className:className, genericArgs: genericArgs, optional: true, pointer: isPointer)
    }
    
    func asNonOptional() -> Type {
        return Type(module: module, name: name,className:className, genericArgs: genericArgs, optional: false, pointer: isPointer)
    }
    
    func withGenericArgs(_ genericArgs: [TypeVar]) -> Type {
        return Type(module: module, name: name, genericArgs: genericArgs, optional: optional, pointer: isPointer)
    }
    
    func withGenericArgs(_ genericArgs: [Type]) -> Type {
        return Type(module: module, name: name, genericArgs: genericArgs, optional: optional, pointer: isPointer)
    }
}

func ==(lhs: Type, rhs: Type) -> Bool {
    return (lhs.hashValue == rhs.hashValue)
}
