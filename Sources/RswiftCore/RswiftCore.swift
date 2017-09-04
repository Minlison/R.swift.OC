//
//  RswiftCore.swift
//  R.swift
//
//  Created by Tom Lokhorst on 2017-04-22.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation
import XcodeEdit

public struct RswiftCore {
    static var isEdgeEnabled = false
    
    static public func run(_ callInformation: CallInformation) throws {
        
        do {
            RswiftCore.isEdgeEnabled = callInformation.edgeEnabled
            
            let xcodeproj = try Xcodeproj(url: callInformation.xcodeprojURL)
            let ignoreFile = (try? IgnoreFile(ignoreFileURL: callInformation.rswiftIgnoreURL)) ?? IgnoreFile()
            
            let resourceURLs = try xcodeproj.resourcePathsForTarget(callInformation.targetName)
                .map { path in path.url(with: callInformation.urlForSourceTreeFolder) }
                .flatMap { $0 }
                .filter { !ignoreFile.matches(url: $0) }
            
            let resources = Resources(resourceURLs: resourceURLs, fileManager: FileManager.default)
            
            let generators: [StructGenerator] = [
                ImageStructGenerator(assetFolders: resources.assetFolders, images: resources.images),
                ColorStructGenerator(colorPalettes: resources.colors),
                        FontStructGenerator(fonts: resources.fonts),
                //        SegueStructGenerator(storyboards: resources.storyboards),
//                StoryboardStructGenerator(storyboards: resources.storyboards),
                NibStructGenerator(nibs: resources.nibs),
//                        ReuseIdentifierStructGenerator(reusables: resources.reusables),
//                        ResourceFileStructGenerator(resourceFiles: resources.resourceFiles),
                StringsStructGenerator(localizableStrings: resources.localizableStrings),
                ]
            
            var allGeneratorsHeader : Set<Module> = []
            
            
            let currentOutPutFileDir = callInformation.outputURL.path
            var isDir : ObjCBool = false
            let isExist = FileManager.default.fileExists(atPath: currentOutPutFileDir, isDirectory: &isDir)
            if !isExist || !isDir.boolValue {
                try FileManager.default.createDirectory(atPath: currentOutPutFileDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            for fileGenerator in generators {
                let result = fileGenerator.generatedStructs(at: callInformation.accessLevel, prefix: "")
                let (externalStructWithoutProperties, internalStruct) = result
//                let (externalStructWithoutProperties, internalStruct) = ValidatedStructGenerator(validationSubject: result)
//                    .generatedStructs(at: callInformation.accessLevel, prefix: "")
                
                let externalStruct = externalStructWithoutProperties//.addingInternalProperties(forBundleIdentifier: callInformation.bundleIdentifier)
                
                let currentFileName = "R_" + result.externalStruct.type.asNoPointer().description.uppercaseFirstCharacter;
                
                let headerCodeConvertibles: [SwiftCodeConverible?] = [
                    HeaderPrinter(),
                    ImportPrinter(
                        modules: callInformation.imports,
                        extractFrom: [externalStruct, internalStruct],
                        exclude: [Module.custom(name: callInformation.productModuleName)]
                    ),
                    externalStruct,
                    internalStruct
                ]
                
                allGeneratorsHeader.update(with: Module.custom(name: currentFileName))
                
                let impCodeConvertibles: [SwiftCodeConverible?] = [
                    HeaderPrinter(),
                    ImportPrinter(
                        modules: [Module.custom(name: currentFileName)],
                        extractFrom: [],
                        exclude: []
                    ),
                    externalStruct,
                    internalStruct
                ]
                
                let fileImp = impCodeConvertibles
                    .flatMap { $0?.ocImp }
                    .joined(separator: "\n\n")
                    + "\n" // Newline at end of file
                
                let fileHeader = headerCodeConvertibles
                    .flatMap { $0?.ocHeader }
                    .joined(separator: "\n\n")
                    + "\n" // Newline at end of file
                
                // Write file if we have changes
                
                let currentFileUrlWithOutExt = URL(fileURLWithPath: currentOutPutFileDir, isDirectory: true).appendingPathComponent(currentFileName)
                let currentFileImpUrl = currentFileUrlWithOutExt.appendingPathExtension("m")
                let currentFileHeaderUrl = currentFileUrlWithOutExt.appendingPathExtension("h")
                
                
                let currentFileImp = try? String(contentsOf: currentFileImpUrl, encoding: .utf8)
                let currentFileHeader = try? String(contentsOf:currentFileHeaderUrl, encoding: .utf8)
                if currentFileImp != fileImp  {
                    do {
                        try fileImp.write(to:currentFileImpUrl, atomically: true, encoding: .utf8)
                    } catch {
                        fail(error.localizedDescription)
                    }
                }
                
                if currentFileHeader != fileHeader  {
                    do {
                        try fileHeader.write(to: currentFileHeaderUrl, atomically: true, encoding: .utf8)
                    } catch {
                        fail(error.localizedDescription)
                    }
                }
            }
            
            let allHeaderCodeConvertibles: [SwiftCodeConverible?] = [
                HeaderPrinter(),
                ImportPrinter(
                    modules: allGeneratorsHeader,
                    extractFrom: [],
                    exclude: []
                )
            ]
            
            let allHeader = allHeaderCodeConvertibles
                .flatMap { $0?.ocHeader }
                .joined(separator: "\n\n")
                + "\n"
            
            
            let allHeaderFileUrlWithOutExt = URL(fileURLWithPath: currentOutPutFileDir, isDirectory: true).appendingPathComponent(callInformation.outputURL.lastPathComponent)
            let allHeaderFileUrl = allHeaderFileUrlWithOutExt.appendingPathExtension("h")
            
            let allHeaderFileHeader = try? String(contentsOf:allHeaderFileUrl, encoding: .utf8)

            if allHeader != allHeaderFileHeader  {
                do {
                    try allHeader.write(to: allHeaderFileUrl, atomically: true, encoding: .utf8)
                } catch {
                    fail(error.localizedDescription)
                }
            }
            
            
        } catch let error as ResourceParsingError {
            switch error {
            case let .parsingFailed(description):
                fail(description)
                
            case let .unsupportedExtension(givenExtension, supportedExtensions):
                let joinedSupportedExtensions = supportedExtensions.joined(separator: ", ")
                fail("File extension '\(String(describing: givenExtension))' is not one of the supported extensions: \(joinedSupportedExtensions)")
            }
            
            exit(3)
        }
    }
}
