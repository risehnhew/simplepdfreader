import Foundation
import SwiftData

@Model
final class PDFItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var localFileName: String
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    var pageCount: Int
    var lastReadPageIndex: Int
    @Relationship(deleteRule: .cascade, inverse: \PDFBookmark.item) var bookmarks: [PDFBookmark]

    init(
        id: UUID = UUID(),
        title: String,
        localFileName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        pageCount: Int = 0,
        lastReadPageIndex: Int = 0,
        bookmarks: [PDFBookmark] = []
    ) {
        self.id = id
        self.title = title
        self.localFileName = localFileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.pageCount = pageCount
        self.lastReadPageIndex = max(0, lastReadPageIndex)
        self.bookmarks = bookmarks
    }

    var sortedBookmarks: [PDFBookmark] {
        bookmarks.sorted { lhs, rhs in
            if lhs.pageIndex == rhs.pageIndex {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.pageIndex < rhs.pageIndex
        }
    }
}

@Model
final class PDFBookmark {
    @Attribute(.unique) var id: UUID
    var pageIndex: Int
    var createdAt: Date
    var note: String?
    var item: PDFItem?

    init(
        id: UUID = UUID(),
        pageIndex: Int,
        createdAt: Date = Date(),
        note: String? = nil,
        item: PDFItem? = nil
    ) {
        self.id = id
        self.pageIndex = max(0, pageIndex)
        self.createdAt = createdAt
        self.note = note
        self.item = item
    }
}
