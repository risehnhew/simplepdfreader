#if DEBUG
import PDFKit
import SwiftData
import UIKit

@MainActor
enum ScreenshotSeedService {
    private static let environmentKey = "SIMPLEPDF_SEED_SAMPLE_LIBRARY"
    private static let title = "Quarterly Reading Notes"
    private static let localFileName = "appstore-sample.pdf"

    static func seedIfRequested(modelContext: ModelContext) {
        guard ProcessInfo.processInfo.environment[environmentKey] == "1" else {
            return
        }

        do {
            var descriptor = FetchDescriptor<PDFItem>(
                predicate: #Predicate { $0.localFileName == localFileName }
            )
            descriptor.fetchLimit = 1

            for existingItem in try modelContext.fetch(descriptor) {
                modelContext.delete(existingItem)
            }

            let pdfURL = try PDFFileStore.fileURL(for: localFileName)
            if FileManager.default.fileExists(atPath: pdfURL.path) {
                try FileManager.default.removeItem(at: pdfURL)
            }
            try createSamplePDF(at: pdfURL)

            let pageCount = PDFDocument(url: pdfURL)?.pageCount ?? 1
            let item = PDFItem(
                title: title,
                localFileName: localFileName,
                lastOpenedAt: Date(),
                pageCount: pageCount
            )
            modelContext.insert(item)
            try modelContext.save()
        } catch {
            assertionFailure("Could not seed screenshot PDF: \(error)")
        }
    }

    private static func createSamplePDF(at url: URL) throws {
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        try renderer.writePDF(to: url) { context in
            context.beginPage()

            UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0).setFill()
            UIRectFill(pageBounds)

            draw("Quarterly Reading Notes", in: CGRect(x: 72, y: 72, width: 468, height: 34), size: 24, weight: .bold, color: UIColor(red: 0.10, green: 0.37, blue: 0.48, alpha: 1.0))
            draw("A sample document for reviewing local PDF reading, search, bookmarks, and page navigation in SimplePDF Reader.", in: CGRect(x: 72, y: 126, width: 468, height: 42), size: 11)
            draw("Highlights", in: CGRect(x: 72, y: 186, width: 468, height: 24), size: 14, weight: .bold)

            let highlights = [
                "- Imported files stay in a private on-device library.",
                "- Search helps locate important passages inside longer documents.",
                "- Bookmarks make frequently referenced pages easy to return to.",
                "- Reader progress is saved locally so documents reopen where you left off."
            ]
            for (index, highlight) in highlights.enumerated() {
                draw(highlight, in: CGRect(x: 90, y: 222 + CGFloat(index * 28), width: 432, height: 20), size: 10.5)
            }

            draw("Review Checklist", in: CGRect(x: 72, y: 354, width: 468, height: 24), size: 14, weight: .bold)
            drawChecklist(in: CGRect(x: 108, y: 398, width: 396, height: 168))
            draw("Use this page to confirm text clarity, table layout, document navigation, and local reading progress.", in: CGRect(x: 72, y: 604, width: 468, height: 42), size: 10)
        }
    }

    private static func draw(
        _ text: String,
        in rect: CGRect,
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor = UIColor(red: 0.16, green: 0.20, blue: 0.22, alpha: 1.0)
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }

    private static func drawChecklist(in rect: CGRect) {
        let rows = [
            ("Feature", "Status"),
            ("Open PDF from library", "Ready"),
            ("Jump between pages", "Ready"),
            ("Search text", "Ready"),
            ("Add bookmark", "Ready"),
            ("Share document", "Ready")
        ]
        let rowHeight = rect.height / CGFloat(rows.count)
        let featureWidth = rect.width * 0.64
        let path = UIBezierPath()

        UIColor(red: 0.91, green: 0.96, blue: 0.98, alpha: 1.0).setFill()
        UIRectFill(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rowHeight))

        UIColor(red: 0.69, green: 0.75, blue: 0.77, alpha: 1.0).setStroke()
        path.lineWidth = 0.6

        for index in 0...rows.count {
            let y = rect.minY + CGFloat(index) * rowHeight
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        [rect.minX, rect.minX + featureWidth, rect.maxX].forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        path.stroke()

        for (index, row) in rows.enumerated() {
            let isHeader = index == 0
            let y = rect.minY + CGFloat(index) * rowHeight + 7
            let color = isHeader ? UIColor(red: 0.10, green: 0.37, blue: 0.48, alpha: 1.0) : UIColor(red: 0.16, green: 0.20, blue: 0.22, alpha: 1.0)
            draw(row.0, in: CGRect(x: rect.minX + 8, y: y, width: featureWidth - 16, height: rowHeight - 8), size: 9, weight: isHeader ? .bold : .regular, color: color)
            draw(row.1, in: CGRect(x: rect.minX + featureWidth + 8, y: y, width: rect.width - featureWidth - 16, height: rowHeight - 8), size: 9, weight: isHeader ? .bold : .regular, color: color)
        }
    }
}
#endif
