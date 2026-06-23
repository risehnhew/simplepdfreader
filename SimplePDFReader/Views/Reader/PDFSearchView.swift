import PDFKit
import SwiftUI

struct PDFSearchResult: Identifiable {
    let id = UUID()
    let pageIndex: Int
    let snippet: String
    let selection: PDFSelection
}

struct PDFSearchView: View {
    let document: PDFDocument
    let onSelect: (PDFSearchResult, [PDFSelection]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [PDFSearchResult] = []
    @State private var selectedResultIndex = 0
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField("Search text", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit {
                            search()
                        }

                    Button {
                        search()
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                if isSearching {
                    ProgressView("Searching")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty {
                    ContentUnavailableView(
                        query.isEmpty ? "Search this PDF" : "No Matches",
                        systemImage: "text.magnifyingglass"
                    )
                } else {
                    List(Array(results.enumerated()), id: \.element.id) { index, result in
                        Button {
                            selectedResultIndex = index
                            selectCurrentResult()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Page \(result.pageIndex + 1)")
                                    .font(.headline)
                                Text(result.snippet)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        moveSelection(by: -1)
                    } label: {
                        Label("Previous", systemImage: "chevron.up")
                    }
                    .disabled(results.isEmpty)

                    Button {
                        moveSelection(by: 1)
                    } label: {
                        Label("Next", systemImage: "chevron.down")
                    }
                    .disabled(results.isEmpty)
                }
            }
        }
    }

    private func search() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            return
        }

        isSearching = true

        let selections = document.findString(trimmedQuery, withOptions: [.caseInsensitive])
        results = selections.prefix(300).map { selection in
            let page = selection.pages.first
            let pageIndex = page.map { document.index(for: $0) } ?? 0
            return PDFSearchResult(
                pageIndex: max(pageIndex, 0),
                snippet: makeSnippet(from: selection),
                selection: selection
            )
        }

        selectedResultIndex = 0
        isSearching = false

        if !results.isEmpty {
            selectCurrentResult()
        }
    }

    private func moveSelection(by offset: Int) {
        guard !results.isEmpty else { return }
        selectedResultIndex = (selectedResultIndex + offset + results.count) % results.count
        selectCurrentResult()
    }

    private func selectCurrentResult() {
        guard results.indices.contains(selectedResultIndex) else { return }
        onSelect(results[selectedResultIndex], results.map(\.selection))
    }

    private func makeSnippet(from selection: PDFSelection) -> String {
        let text = selection.string?
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ") ?? "Text match"

        if text.count <= 140 {
            return text
        }

        return "\(String(text.prefix(137)))..."
    }
}
