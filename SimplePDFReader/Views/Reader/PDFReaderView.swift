import PDFKit
import SwiftData
import SwiftUI

struct PDFReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var item: PDFItem

    @State private var document: PDFDocument?
    @State private var isLoading = true
    @State private var loadErrorMessage: String?
    @State private var currentPageIndex = 0
    @State private var highlightedSelections: [PDFSelection] = []
    @State private var pendingPageIndex: Int?
    @State private var isShowingSearch = false
    @State private var isShowingBookmarks = false
    @State private var isShowingJumpToPage = false
    @State private var isShowingDocumentInfo = false
    @State private var isConfirmingDelete = false

    private var pageCount: Int {
        document?.pageCount ?? item.pageCount
    }

    private var currentPageIsBookmarked: Bool {
        item.bookmarks.contains { $0.pageIndex == currentPageIndex }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Opening PDF")
            } else if let document {
                ZStack(alignment: .bottom) {
                    PDFKitRepresentedView(
                        document: document,
                        currentPageIndex: $currentPageIndex,
                        highlightedSelections: $highlightedSelections,
                        pendingPageIndex: $pendingPageIndex
                    )
                    .ignoresSafeArea(edges: .bottom)

                    pageIndicator
                }
            } else {
                ContentUnavailableView {
                    Label("Unable to Open PDF", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadErrorMessage ?? "The file may be damaged, missing, or unsupported.")
                }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingSearch = true
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .disabled(document == nil)

                Button {
                    toggleBookmark()
                } label: {
                    Label("Bookmark", systemImage: currentPageIsBookmarked ? "bookmark.fill" : "bookmark")
                }
                .disabled(document == nil)

                Menu {
                    Button {
                        isShowingJumpToPage = true
                    } label: {
                        Label("Jump to Page", systemImage: "number")
                    }
                    .disabled(document == nil || pageCount == 0)

                    Button {
                        isShowingBookmarks = true
                    } label: {
                        Label("Bookmarks", systemImage: "bookmark")
                    }
                    .disabled(document == nil)

                    if let url = try? PDFFileStore.fileURL(for: item.localFileName) {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button {
                        isShowingDocumentInfo = true
                    } label: {
                        Label("Document Info", systemImage: "info.circle")
                    }
                    .disabled(document == nil)

                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("Delete from Library", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .task {
            await loadDocument()
        }
        .onChange(of: currentPageIndex) { _, _ in
            persistCurrentPage()
        }
        .onDisappear {
            persistCurrentPage()
        }
        .sheet(isPresented: $isShowingSearch) {
            if let document {
                PDFSearchView(document: document) { result, allSelections in
                    highlightedSelections = allSelections
                    jump(to: result.pageIndex)
                }
            }
        }
        .sheet(isPresented: $isShowingBookmarks) {
            BookmarksView(item: item) { pageIndex in
                jump(to: pageIndex)
            }
        }
        .sheet(isPresented: $isShowingJumpToPage) {
            JumpToPageView(
                pageCount: max(pageCount, 1),
                currentPageIndex: currentPageIndex
            ) { pageIndex in
                jump(to: pageIndex)
            }
        }
        .sheet(isPresented: $isShowingDocumentInfo) {
            if let document {
                DocumentInfoView(item: item, document: document)
            }
        }
        .alert("Delete PDF?", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCurrentPDF()
            }
        } message: {
            Text("This removes the PDF from the local library and deletes the app's copy of the file.")
        }
    }

    private var pageIndicator: some View {
        Button {
            isShowingJumpToPage = true
        } label: {
            Text("Page \(min(currentPageIndex + 1, max(pageCount, 1))) / \(max(pageCount, 1))")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 18)
        .disabled(pageCount == 0)
    }

    @MainActor
    private func loadDocument() async {
        guard document == nil else { return }

        isLoading = true
        loadErrorMessage = nil

        do {
            let url = try PDFFileStore.fileURL(for: item.localFileName)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw PDFLibraryError.missingLocalFile
            }

            let loadedDocument = await Task.detached(priority: .userInitiated) {
                PDFDocument(url: url)
            }.value

            guard let loadedDocument else {
                throw PDFLibraryError.invalidPDF
            }

            if loadedDocument.isEncrypted && loadedDocument.isLocked {
                throw PDFLibraryError.encryptedPDF
            }

            document = loadedDocument
            let maxPageIndex = max(loadedDocument.pageCount - 1, 0)
            currentPageIndex = min(max(item.lastReadPageIndex, 0), maxPageIndex)
            pendingPageIndex = currentPageIndex
            item.pageCount = loadedDocument.pageCount
            item.lastOpenedAt = Date()
            item.updatedAt = Date()
            try? modelContext.save()
        } catch {
            loadErrorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func jump(to pageIndex: Int) {
        let clampedPageIndex = min(max(pageIndex, 0), max(pageCount - 1, 0))
        pendingPageIndex = clampedPageIndex
        currentPageIndex = clampedPageIndex
    }

    private func persistCurrentPage() {
        guard document != nil else { return }
        item.lastReadPageIndex = min(max(currentPageIndex, 0), max(pageCount - 1, 0))
        item.updatedAt = Date()
        try? modelContext.save()
    }

    private func toggleBookmark() {
        guard document != nil else { return }

        if let bookmark = item.bookmarks.first(where: { $0.pageIndex == currentPageIndex }) {
            if let index = item.bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
                item.bookmarks.remove(at: index)
            }
            modelContext.delete(bookmark)
        } else {
            let bookmark = PDFBookmark(pageIndex: currentPageIndex, item: item)
            item.bookmarks.append(bookmark)
        }

        item.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteCurrentPDF() {
        do {
            try PDFFileStore.deletePDF(named: item.localFileName)
        } catch PDFLibraryError.missingLocalFile {
            // The metadata should still be removed when the sandbox file is gone.
        } catch {
            loadErrorMessage = error.localizedDescription
            return
        }

        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}
