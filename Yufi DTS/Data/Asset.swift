//
//  Asset.swift
//  Yufi
//
//  Created by Nick Yang on 1/31/24.
//

import Foundation
import SwiftData
import SwiftUI
import OSLog

@Model
final class Asset {
    var assetIdentifier: UUID // we need this ID to check when adding and removing assets; PersistentModel.PersistentIdentifer is not always available upon entry creation, so we need to craete our own
    var entryIdentifier: UUID
    var referencedFileLocation: String?
    var assetType: String
    
    @Relationship(deleteRule: .nullify) var entry: Entry?
    
    init(entryIdentifier: UUID, assetType: String) {
        self.assetIdentifier = UUID()
        self.entryIdentifier = entryIdentifier
        self.assetType = assetType
    }
    
    
    
    let assetDirectoryName = "Assets" // The name of the directory inside document file package that stores all the referenced asset files
    
    //MARK: - Image related funcions and properties
    
    /// Image view with the referenced iamge file
    /// - Parameter documentURL: user's ModelDocument file URL
    /// - Returns: Image view if successful, nil if unable to read referenced image file.
    func image(_ documentURL: URL?) -> Image? {
        if let documentURL {
            if self.referencedFileLocation != nil {
                if let image = getReferencedImage(documentURL: documentURL) {
                    let rep = image.representations[0]
                    image.size = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
                    return Image(nsImage: image)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        return nil
    }
    
    
    /// Save image inside ModelDocument file
    /// - Parameters:
    ///   - data: image data to be saved as file
    ///   - documentURL: user ModelDocument file URL
    ///
    ///   Problem: request to access the documentURL is granted, and the file is written into the ModelDocument file URL. But a dialog box is prompted that the ModelDocument file has been changed by another user. Clicking on any button removes the folder and image file that was just saved.
    func saveReferencedImage(data: Data, documentURL: URL?) throws {
        let logger = Logger(subsystem: "saveReferencedImage", category: "Asset")
        
        if let documentURL {
            let yearInt = Calendar.current.component(.year, from: Date())
            let monthInt = Calendar.current.component(.month, from: Date())
            // create the appropriate folder path by year/month inside the file package
            let assetDirectorySegment = "\(assetDirectoryName)/\(yearInt)/\(monthInt)"
            let referencedFileName = "\(entryIdentifier)_\(assetIdentifier).\(assetType)"
            
            let referenceFileDirectoryURL = documentURL.appending(component: assetDirectorySegment)
            let referenceFileURL = referenceFileDirectoryURL.appending(component: referencedFileName)
            
            // request access to the ModelDocument file package
            if documentURL.startAccessingSecurityScopedResource() {
                if !FileManager.default.fileExists(atPath: referenceFileDirectoryURL.path()) {
                    do {
                        try FileManager.default.createDirectory(at: referenceFileDirectoryURL, withIntermediateDirectories: true)
                    } catch {
                        documentURL.stopAccessingSecurityScopedResource()
                        throw AssetFileOperationError.unableToCreateReferencedDirectory(error.localizedDescription)
                    }
                }
                
                if FileManager.default.fileExists(atPath: referenceFileURL.path()) {
                    documentURL.stopAccessingSecurityScopedResource()
                    throw AssetFileOperationError.duplicateReferenceFileDetected
                }
                
                do {
                    try data.write(to: referenceFileURL, options: [])
                } catch {
                    logger.debug("ERROR data.write()  \(error)")
                    documentURL.stopAccessingSecurityScopedResource()
                    throw AssetFileOperationError.unableToSaveReferenceFile
                }
                
                // save the location of the image file inside the ModelDocument file package so we can use it to read the image file.
                self.referencedFileLocation = assetDirectorySegment + "/" + referencedFileName
                
                logger.debug("Successfully saved image data to: \(referenceFileURL)")
            }
            documentURL.stopAccessingSecurityScopedResource()
        } else {
            logger.debug("ERROR! Unable to save referenced image file because document URL is nil.")
        }
    }
    
    /// Read and return a NSImage inside the user ModelDocument file package
    /// - Parameter documentURL: user's ModelDocument file URL
    /// - Returns: NSImage of the referenced image file. nil if unable to read or image file doesn't exists.
    func getReferencedImage(documentURL: URL) -> NSImage? {
        let logger = Logger(subsystem: "getReferencedImage", category: "Asset")
        if let referencedFileLocation = self.referencedFileLocation {
            if documentURL.startAccessingSecurityScopedResource() {
                let referencedFileURL = documentURL.appending(component: "\(referencedFileLocation)")
                if FileManager.default.fileExists(atPath: referencedFileURL.path()) {
                    if let image = NSImage(byReferencingFile: referencedFileURL.path()) {
                        return image
                    } else {
                        logger.debug("ERROR! Unable to read the image file at: \(referencedFileURL.path()).")
                    }
                } else {
                    logger.debug("ERROR! Referenced image file does not exist at \(referencedFileURL.path()).")
                }
            } else {
                logger.debug("ERROR! Unable to get access to Document file to read image data.")
            }
        } else {
            logger.debug("ERROR! Asset entry does not have a valid referenced file location.")
        }
        
        documentURL.stopAccessingSecurityScopedResource()
        return nil
    }

    
    enum AssetFileOperationError: Error {
        case unableToCreateReferencedDirectory(String)
        case duplicateReferenceFileDetected
        case unableToSaveReferenceFile
    }
    
}
