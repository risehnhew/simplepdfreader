import SwiftUI

struct JumpToPageView: View {
    let pageCount: Int
    let currentPageIndex: Int
    let onJump: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pageNumber: Int

    init(pageCount: Int, currentPageIndex: Int, onJump: @escaping (Int) -> Void) {
        self.pageCount = max(pageCount, 1)
        self.currentPageIndex = currentPageIndex
        self.onJump = onJump
        _pageNumber = State(initialValue: min(max(currentPageIndex + 1, 1), max(pageCount, 1)))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $pageNumber, in: 1...pageCount) {
                        Text("Page \(pageNumber) of \(pageCount)")
                    }

                    Slider(
                        value: Binding(
                            get: { Double(pageNumber) },
                            set: { pageNumber = Int($0.rounded()) }
                        ),
                        in: 1...Double(pageCount),
                        step: 1
                    )
                }
            }
            .navigationTitle("Jump to Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Jump") {
                        onJump(pageNumber - 1)
                        dismiss()
                    }
                }
            }
        }
    }
}
