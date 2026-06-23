import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pdfItems: [PDFItem]
    @AppStorage("appearanceMode") private var appearanceModeRawValue = AppearanceMode.system.rawValue

    @State private var isConfirmingReset = false
    @State private var resetErrorMessage: String?

    private var appearanceMode: Binding<AppearanceMode> {
        Binding {
            AppearanceMode(rawValue: appearanceModeRawValue) ?? .system
        } set: { mode in
            appearanceModeRawValue = mode.rawValue
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Privacy") {
                    Text("SimplePDF Reader stores imported PDF files locally on your device. The app does not upload your documents, does not require an account, and does not track you.")
                        .font(.subheadline)
                }

                Section("Support") {
                    LabeledContent("Support Email", value: "Set before release")
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Button(role: .destructive) {
                        isConfirmingReset = true
                    } label: {
                        Label("Reset Local Library", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Local Library?", isPresented: $isConfirmingReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetLibrary()
                }
            } message: {
                Text("This deletes all imported PDFs and local metadata from this device.")
            }
            .alert(
                "Reset Failed",
                isPresented: Binding(
                    get: { resetErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            resetErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetErrorMessage ?? "")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func resetLibrary() {
        do {
            for item in pdfItems {
                modelContext.delete(item)
            }
            try PDFFileStore.resetLibraryStorage()
            try modelContext.save()
        } catch {
            resetErrorMessage = error.localizedDescription
        }
    }
}
