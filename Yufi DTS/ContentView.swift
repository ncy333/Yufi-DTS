//
//  ContentView.swift
//  Yufi DTS
//
//  Created by Nick Yang on 7/7/24.
//

import SwiftUI
import SwiftData
import OSLog

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.documentConfiguration) private var documentConfiguration
    
    @Query private var entries: [Entry]
    
    // present a file importer UI to select an image file to be saved into the ModelDocument file packge.
    @State var isShowingImageFileImporter = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        Text("Entry at \(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        Text("Referenced image located at: \(documentConfiguration!.fileURL!.path()) \(entry.assets?.first!.referencedFileLocation ?? "error")")
                        if let image = entry.assets?.first!.getReferencedImage(documentURL: (documentConfiguration?.fileURL)!) {
                            Image(nsImage: image)
                        }
                    } label: {
                        Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Image entry", systemImage: "plus")
                    }
                    .disabled(documentConfiguration?.fileURL == nil)
                }
            }
        } detail: {
            if documentConfiguration?.fileURL == nil {
                Text("Please save the file first before proceeding.")
                    .foregroundStyle(.red)
            } else {
                Text("Press the + button to select an image file to create a new entry.")
            }
        }
        .fileImporter(isPresented: $isShowingImageFileImporter, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let fileUrl):
                //fileURL = fileUrl
                let gotAccess = fileUrl.startAccessingSecurityScopedResource()
                if !gotAccess { return }
                do {
                    let imageData = try Data(contentsOf: fileUrl)
                    fileUrl.stopAccessingSecurityScopedResource()
                    
                    let newEntry = Entry(entryType: .image)
                    let newAsset = Asset(entryIdentifier: newEntry.identifier, assetType: fileUrl.pathExtension.lowercased())
                    newEntry.assets?.append(newAsset)
                    
                    try newAsset.saveReferencedImage(data: imageData, documentURL: documentConfiguration?.fileURL)
                    
                    modelContext.insert(newEntry)
                } catch {
                    let errorLog = Logger(subsystem: "NewEntrySheet", category: "image fileImporter")
                    errorLog.error("*** ERROR - Can't convert file into data object in fileImporter")
                }
            case .failure(let error):
                let errorLog = Logger(subsystem: "NewEntrySheet", category: "image fileImporter")
                errorLog.error("*** ERROR - Unable to open image file in NewEntrySheet \(error)")
            }
        }
    }

    private func addItem() {
        withAnimation {
            isShowingImageFileImporter = true
        }
    }

    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
