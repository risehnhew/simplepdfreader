import SwiftUI

struct PDFItemRow: View {
    let item: PDFItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 34, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(pageCountText)
                    Text("Last read: \(lastReadPageText)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(lastOpenedText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var pageCountText: String {
        item.pageCount == 1 ? "1 page" : "\(item.pageCount) pages"
    }

    private var lastReadPageText: String {
        guard item.pageCount > 0 else { return "Unknown" }
        let page = min(max(item.lastReadPageIndex + 1, 1), item.pageCount)
        return "\(page) / \(item.pageCount)"
    }

    private var lastOpenedText: String {
        guard let lastOpenedAt = item.lastOpenedAt else {
            return "Not opened yet"
        }
        return "Last opened \(lastOpenedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
