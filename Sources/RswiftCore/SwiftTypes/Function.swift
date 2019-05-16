//
//  Function.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct Function: UsedTypesProvider, SwiftCodeConverible, Hashable {
    let comments: [String]
    let accessModifier: AccessLevel
    let isStatic: Bool
    let name: SwiftIdentifier
    let generics: String?
    let parameters: [Parameter]
    let doesThrow: Bool
    let returnType: Type
    let body: String
    
    init(comments: [String], accessModifier: AccessLevel, isStatic: Bool, name: SwiftIdentifier, generics: String?, parameters: [Parameter], doesThrow: Bool, returnType: Type, body: String) {
        self.comments = comments
        self.accessModifier = accessModifier
        self.isStatic = isStatic
        self.name = name
        self.generics = generics
        self.parameters = parameters
        self.doesThrow = doesThrow
        self.returnType = returnType
        self.body = body
    }
    
    private func adjuestFunction() -> [Function] {
        
        var functions : Set<Function> = []
        var index = 0
        if parameters.count == 0
        {
            let fuc0 = Function(comments: comments, accessModifier: accessModifier, isStatic: isStatic, name: name, generics: generics, parameters: parameters, doesThrow: doesThrow, returnType: returnType, body: body)
            functions.insert(fuc0)
        }
        else
        {
            for param in parameters {
                var originBody = body
                var originParams = parameters
                
                if param.type == Type._Void {
                    
                    originParams.remove(at: index)
                    originBody = originBody.replacingOccurrences(of: param.name, with: param.defaultValue!)
                    let fuc3 = Function(comments: comments, accessModifier: accessModifier, isStatic: isStatic, name: name, generics: generics, parameters: originParams, doesThrow: doesThrow, returnType: returnType, body: originBody)
                    functions.insert(fuc3)
                } else {
                    let fuc1 = Function(comments: comments, accessModifier: accessModifier, isStatic: isStatic, name: name, generics: generics, parameters: originParams, doesThrow: doesThrow, returnType: returnType, body: body)
                    
                    if param.type.optional == true {
                        originParams.remove(at: index)
                        originBody = originBody.replacingOccurrences(of: param.name, with: param.defaultValue!)
                        let fuc2 = Function(comments: comments, accessModifier: accessModifier, isStatic: isStatic, name: name, generics: generics, parameters: originParams, doesThrow: doesThrow, returnType: returnType, body: originBody)
                        functions.insert(fuc2)
                    }
                    
                    functions.insert(fuc1)
                }
                
                index = index + 1
            }
        }
        
        return functions.map{ $0 }
    }
    var usedTypes: [UsedType] {
        return [
            returnType.usedTypes,
            parameters.flatMap(getUsedTypes),
            ].flatten()
    }
    
    var swiftCode: String {
        let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
        let accessModifierString = accessModifier.swiftCode
        let staticString = isStatic ? "static " : ""
        let genericsString = generics.map { "<\($0)>" } ?? ""
        let parameterString = parameters.map { $0.description }.joined(separator: ", ")
        let throwString = doesThrow ? " throws" : ""
        let returnString = Type._Void == returnType ? "" : " -> \(returnType)"
        let bodyString = body.indent(with: "  ")
        
        return "\(commentsString)\(accessModifierString)\(staticString)func \(name)\(genericsString)(\(parameterString))\(throwString)\(returnString) {\n\(bodyString)\n}"
    }
    
    var _ocHeader : String {
        let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
        //        let accessModifierString = accessModifier.swiftCode
        //        let staticString = isStatic ? "static " : ""
        //        let genericsString = generics.map { "<\($0)>" } ?? ""
        let parameterString = parameters.map { $0.description.uppercaseFirstCharacter }.joined(separator: " ")
        //        let throwString = doesThrow ? " throws" : ""
        let returnString = Type._Void == returnType ? "void" : "\(returnType.description)"
        //        let bodyString = body.indent(with: "  ")
        
        return "\n\(commentsString)+ (\(returnString))\(name)\(parameterString);"
        
    }
    
    var _ocImp : String {
        let commentsString = comments.map { "/// \($0)\n" }.joined(separator: "")
        //        let accessModifierString = accessModifier.swiftCode
        //        let staticString = isStatic ? "static " : ""
        //        let genericsString = generics.map { "<\($0)>" } ?? ""
        let parameterString = parameters.map { $0.description.uppercaseFirstCharacter }.joined(separator: " ")
        //        let throwString = doesThrow ? " throws" : ""
        let returnString = Type._Void == returnType ? "void" : "\(returnType.description)"
        let bodyString = body.indent(with: "     ")
        
        
        return "\n\(commentsString)+ (\(returnString))\(name)\(parameterString) {\n\(bodyString)\n}"
        
    }
    
    var ocHeader : String {
        return adjuestFunction().map{$0._ocHeader}.joined(separator: "\n")
    }
    
    var ocImp : String {
        return adjuestFunction().map{$0._ocImp}.joined(separator: "\n")
    }
    
    struct Parameter: UsedTypesProvider, CustomStringConvertible {
        let name: String
        let localName: String?
        let type: Type
        let defaultValue: String?
        
        var usedTypes: [UsedType] {
            return type.usedTypes
        }
        
        var swiftIdentifier: SwiftIdentifier {
            return SwiftIdentifier(name: name, lowercaseStartingCharacters: false)
        }
        
        var description: String {
            let definition = localName.map({ "\(swiftIdentifier):(\(type))\($0)" }) ?? "\(swiftIdentifier):(\(type))\(swiftIdentifier)"
            return definition
        }
        
        init(name: String, type: Type, defaultValue: String? = nil) {
            self.name = name
            self.localName = nil
            self.type = type
            self.defaultValue = defaultValue
        }
        
        init(name: String, localName: String?, type: Type, defaultValue: String? = nil) {
            self.name = name
            self.localName = localName
            self.type = type
            self.defaultValue = defaultValue
        }
    }
    var hashValue: Int {
        let str = _ocImp + _ocHeader
        return str.hashValue
    }
    static public func ==(lhs: Function, rhs: Function) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
