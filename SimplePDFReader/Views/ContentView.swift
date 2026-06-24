import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .task {
            #if DEBUG
            ScreenshotSeedService.seedIfRequested(modelContext: modelContext)
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PDFItem.self, PDFBookmark.self], inMemory: true)
}
