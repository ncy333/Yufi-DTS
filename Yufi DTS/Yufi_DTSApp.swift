//
//  Yufi_DTSApp.swift
//  Yufi DTS
//
//  Created by Nick Yang on 7/7/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct Yufi_DTSApp: App {
    var body: some Scene {
        DocumentGroup(editing: Entry.self, contentType: .yufiDocument) {
            ContentView()
        }
    }
}

extension UTType {
    static var yufiDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}
