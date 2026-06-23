import SwiftData
import SwiftUI

@main
struct SimplePDFReaderApp: App {
    @AppStorage("appearanceMode") private var appearanceModeRawValue = AppearanceMode.system.rawValue

    init() {
        Self.prepareApplicationSupportDirectory()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(AppearanceMode(rawValue: appearanceModeRawValue)?.colorScheme)
        }
        .modelContainer(for: [PDFItem.self, PDFBookmark.self])
    }

    private static func prepareApplicationSupportDirectory() {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return
        }

        try? FileManager.default.createDirectory(
            at: applicationSupportURL,
            withIntermediateDirectories: true
        )
    }
}
