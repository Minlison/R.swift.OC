//
//  Rswift.swift
//  R.swift
//
//  Created by Tom Lokhorst on 2017-04-22.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct Rswift {
    static let version = "3.3.0"
    static let resourceFileName = "R.generated.swift"
}

enum RSwiftOC : String {
    case Generated = "R.generated"
    case Image = "Image"
    case Font = "Font"
    case ResourceFile = "ResourceFile"
    case Color = "Color"
    case LocalizedString = "LocalizedString"
    case Storyboard = "Storyboard"
    case Segues = "Segues"
    case Nib = "Nib"
    case ReusableCell = "ReusableCell"
    
    func header() -> String {
        return "R.\(self).h"
    }
    func impl() -> String {
        return "R.\(self).m"
    }
}
