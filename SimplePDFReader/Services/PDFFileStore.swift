import Foundation
import PDFKit

enum PDFLibraryError: LocalizedError {
    case invalidPDF
    case missingLocalFile
    case encryptedPDF

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "This file could not be opened as a PDF."
        case .missingLocalFile:
            return "The local PDF file could not be found."
        case .encryptedPDF:
            return "This PDF is password protected and cannot be opened in this version."
        }
    }
}

struct PDFImportResult {
    let title: String
    let localFileName: String
    let pageCount: Int
}

enum PDFFileStore {
    static let importedPDFDirectoryName = "ImportedPDFs"

    static func libraryDirectory() throws -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let directoryURL = applicationSupportURL.appendingPathComponent(importedPDFDirectoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
        }

        return directoryURL
    }

    static func fileURL(for localFileName: String) throws -> URL {
        try libraryDirectory().appendingPathComponent(localFileName)
    }

    static func newInternalFileName() -> String {
        "\(UUID().uuidString).pdf"
    }

    static func sanitizedTitle(from url: URL) -> String {
        let rawTitle = url.deletingPathExtension().lastPathComponent
        let unsafeCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let components = rawTitle
            .components(separatedBy: unsafeCharacters)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        let title = components.joined(separator: " ")
        return title.isEmpty ? "Untitled PDF" : title
    }

    static func deletePDF(named localFileName: String) throws {
        let url = try fileURL(for: localFileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFLibraryError.missingLocalFile
        }
        try FileManager.default.removeItem(at: url)
    }

    static func resetLibraryStorage() throws {
        let directoryURL = try libraryDirectory()
        if FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.removeItem(at: directoryURL)
        }
        _ = try libraryDirectory()
    }
}

enum PDFImportService {
    static func importPDF(from sourceURL: URL) async throws -> PDFImportResult {
        try await Task.detached(priority: .userInitiated) {
            let didAccessSecurityScopedResource = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didAccessSecurityScopedResource {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            guard sourceURL.pathExtension.lowercased() == "pdf" else {
                throw PDFLibraryError.invalidPDF
            }

            let title = PDFFileStore.sanitizedTitle(from: sourceURL)
            let localFileName = PDFFileStore.newInternalFileName()
            let destinationURL = try PDFFileStore.fileURL(for: localFileName)

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            guard let document = PDFDocument(url: destinationURL) else {
                try? FileManager.default.removeItem(at: destinationURL)
                throw PDFLibraryError.invalidPDF
            }

            return PDFImportResult(
                title: title,
                localFileName: localFileName,
                pageCount: document.pageCount
            )
        }.value
    }
}
