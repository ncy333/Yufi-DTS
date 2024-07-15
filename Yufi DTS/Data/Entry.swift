//
//  Entry.swift
//  
//
//  Created by Nick Yang on 10/14/23.
//
//

import Foundation
import SwiftData

@Model
final class Entry {
    var creationTime: Date
    var entryTypeValue: Int16 = 100 // default to text
    @Attribute(.unique) var identifier: UUID
    var keywords: String = ""
    var modificationTime: Date
    var textEntry: String = ""
    var timestamp: Date
    var title: String
    
    @Relationship(deleteRule: .cascade, inverse: \Asset.entry) var assets: [Asset]?
    
    init(entryType: EntryType, title: String = "") {
        self.identifier = UUID()
        let currentTime = Date.now
        self.creationTime = currentTime
        self.modificationTime = currentTime
        self.timestamp = currentTime
        self.entryTypeValue = entryType.rawValue
        self.title = title
    }
    
    var entryType: EntryType {
        get {
            return EntryType(rawValue: entryTypeValue) ?? .text
        }
        set {
            entryTypeValue = newValue.rawValue
        }
    }

}

public enum EntryType: Int16, Codable, Identifiable {
    case text = 100
    case image = 300
    case video = 600
    case pdf = 700
    case web = 800
    //case audio = "audio"
    
    public var id: Self { self }
}


