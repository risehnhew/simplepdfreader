import XCTest
@testable import SimplePDFReader

final class PDFFileStoreTests: XCTestCase {
    func testSanitizedTitleRemovesUnsafeCharactersAndExtension() {
        let url = URL(fileURLWithPath: "/tmp/Quarterly:Report?.pdf")

        XCTAssertEqual(PDFFileStore.sanitizedTitle(from: url), "Quarterly Report")
    }

    func testSanitizedTitleFallsBackWhenTitleIsEmpty() {
        let url = URL(fileURLWithPath: "/tmp/<>.pdf")

        XCTAssertEqual(PDFFileStore.sanitizedTitle(from: url), "Untitled PDF")
    }

    func testNewInternalFileNameUsesPDFExtension() {
        let fileName = PDFFileStore.newInternalFileName()

        XCTAssertTrue(fileName.hasSuffix(".pdf"))
        XCTAssertNotNil(UUID(uuidString: String(fileName.dropLast(4))))
    }
}
