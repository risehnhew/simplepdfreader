import PDFKit
import SwiftUI

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPageIndex: Int
    @Binding var highlightedSelections: [PDFSelection]
    @Binding var pendingPageIndex: Int?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.backgroundColor = .systemBackground
        pdfView.delegate = context.coordinator

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        if let initialPage = document.page(at: currentPageIndex) {
            pdfView.go(to: initialPage)
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
        }

        pdfView.highlightedSelections = highlightedSelections

        if let pageIndex = pendingPageIndex,
           let page = document.page(at: pageIndex) {
            pdfView.go(to: page)
            DispatchQueue.main.async {
                currentPageIndex = pageIndex
                pendingPageIndex = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPageIndex: $currentPageIndex)
    }

    final class Coordinator: NSObject, PDFViewDelegate {
        @Binding private var currentPageIndex: Int

        init(currentPageIndex: Binding<Int>) {
            _currentPageIndex = currentPageIndex
        }

        @objc func pageChanged(_ notification: Notification) {
            guard
                let pdfView = notification.object as? PDFView,
                let page = pdfView.currentPage,
                let document = pdfView.document
            else {
                return
            }

            let pageIndex = document.index(for: page)
            guard pageIndex != NSNotFound else { return }

            DispatchQueue.main.async {
                self.currentPageIndex = pageIndex
            }
        }
    }
}
