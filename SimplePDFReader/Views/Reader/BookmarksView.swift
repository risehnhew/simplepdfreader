import SwiftData
import SwiftUI

struct BookmarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var item: PDFItem
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if item.sortedBookmarks.isEmpty {
                    ContentUnavailableView("No Bookmarks", systemImage: "bookmark")
                } else {
                    List {
                        ForEach(item.sortedBookmarks) { bookmark in
                            Button {
                                onSelect(bookmark.pageIndex)
                                dismiss()
                            } label: {
                                HStack {
                                    Label("Page \(bookmark.pageIndex + 1)", systemImage: "bookmark.fill")
                                    Spacer()
                                    Text(bookmark.createdAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    remove(bookmark)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
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

    private func remove(_ bookmark: PDFBookmark) {
        if let index = item.bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            item.bookmarks.remove(at: index)
        }
        modelContext.delete(bookmark)
        item.updatedAt = Date()
        try? modelContext.save()
    }
}
