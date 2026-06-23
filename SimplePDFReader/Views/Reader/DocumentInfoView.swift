import PDFKit
import SwiftUI

struct DocumentInfoView: View {
    let item: PDFItem
    let document: PDFDocument

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Document") {
                    row(title: "Title", value: item.title)
                    row(title: "Pages", value: "\(document.pageCount)")
                    row(title: "Bookmarks", value: "\(item.bookmarks.count)")
                    row(title: "File Size", value: fileSizeText)
                }

                Section("Library") {
                    row(title: "Imported", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    row(title: "Updated", value: item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    row(title: "Last Opened", value: item.lastOpenedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not opened")
                    row(title: "Internal File", value: item.localFileName)
                }
            }
            .navigationTitle("Document Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func row(title: String, value: String) -> some View {
        LabeledContent(title, value: value)
    }

    private var fileSizeText: String {
        guard
            let url = try? PDFFileStore.fileURL(for: item.localFileName),
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? NSNumber
        else {
            return "Unknown"
        }

        return ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
    }
}
