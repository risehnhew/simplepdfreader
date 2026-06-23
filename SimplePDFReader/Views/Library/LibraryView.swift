import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PDFItem.updatedAt, order: .reverse) private var pdfItems: [PDFItem]

    @State private var searchText = ""
    @State private var isShowingImporter = false
    @State private var importErrorMessage: String?
    @State private var itemBeingRenamed: PDFItem?
    @State private var renameText = ""
    @State private var isImporting = false

    private var filteredItems: [PDFItem] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else { return pdfItems }
        return pdfItems.filter { item in
            item.title.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pdfItems.isEmpty && !isImporting {
                    ContentUnavailableView {
                        Label("Import your first PDF", systemImage: "doc.badge.plus")
                    } actions: {
                        Button {
                            isShowingImporter = true
                        } label: {
                            Label("Import PDF", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if isImporting {
                            HStack {
                                ProgressView()
                                Text("Importing PDFs")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ForEach(filteredItems) { item in
                            NavigationLink {
                                PDFReaderView(item: item)
                            } label: {
                                PDFItemRow(item: item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    beginRename(item)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    beginRename(item)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }

                                if let url = try? PDFFileStore.fileURL(for: item.localFileName) {
                                    ShareLink(item: url) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                }

                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingImporter = true
                    } label: {
                        Label("Import", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search PDFs")
            .sheet(isPresented: $isShowingImporter) {
                DocumentPicker { urls in
                    importPDFs(from: urls)
                }
            }
            .alert(
                "Import Failed",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            importErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "")
            }
            .alert(
                "Rename PDF",
                isPresented: Binding(
                    get: { itemBeingRenamed != nil },
                    set: { isPresented in
                        if !isPresented {
                            itemBeingRenamed = nil
                        }
                    }
                )
            ) {
                TextField("Title", text: $renameText)
                Button("Cancel", role: .cancel) {
                    itemBeingRenamed = nil
                }
                Button("Save") {
                    commitRename()
                }
            }
        }
    }

    @MainActor
    private func importPDFs(from urls: [URL]) {
        guard !urls.isEmpty else { return }

        isImporting = true

        Task { @MainActor in
            var failures: [String] = []

            for url in urls {
                do {
                    let result = try await PDFImportService.importPDF(from: url)
                    let now = Date()
                    let item = PDFItem(
                        title: result.title,
                        localFileName: result.localFileName,
                        createdAt: now,
                        updatedAt: now,
                        pageCount: result.pageCount
                    )
                    modelContext.insert(item)
                } catch {
                    failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }

            do {
                try modelContext.save()
            } catch {
                failures.append("Library metadata could not be saved: \(error.localizedDescription)")
            }

            isImporting = false

            if !failures.isEmpty {
                importErrorMessage = failures.joined(separator: "\n")
            }
        }
    }

    private func beginRename(_ item: PDFItem) {
        itemBeingRenamed = item
        renameText = item.title
    }

    private func commitRename() {
        let trimmedTitle = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let item = itemBeingRenamed, !trimmedTitle.isEmpty else {
            itemBeingRenamed = nil
            return
        }

        item.title = trimmedTitle
        item.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            importErrorMessage = "The PDF could not be renamed: \(error.localizedDescription)"
        }

        itemBeingRenamed = nil
    }

    private func delete(_ item: PDFItem) {
        do {
            try PDFFileStore.deletePDF(named: item.localFileName)
        } catch PDFLibraryError.missingLocalFile {
            // Metadata can still be removed if the sandbox file was already missing.
        } catch {
            importErrorMessage = "The local file could not be deleted: \(error.localizedDescription)"
            return
        }

        modelContext.delete(item)

        do {
            try modelContext.save()
        } catch {
            importErrorMessage = "The library entry could not be deleted: \(error.localizedDescription)"
        }
    }
}
