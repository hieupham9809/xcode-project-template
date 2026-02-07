import XCTest
@testable import SmartSubscriptionKit

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

final class AppleVisionOCRServiceTests: XCTestCase {
    var sut: AppleVisionOCRService!

    override func setUp() async throws {
        try await super.setUp()
        sut = AppleVisionOCRService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testServiceInitialization() {
        XCTAssertNotNil(sut)
    }

    // MARK: - Text Extraction Tests

    func testExtractTextFromImageWithText() async throws {
        // Create a simple test image with text
        let testImage = createTestImage(withText: "Test Invoice\nTotal: $99.99\nDate: 2024-01-01")
        guard let imageData = imageData(from: testImage) else {
            XCTFail("Failed to create test image data")
            return
        }

        // Act
        let extractedText = try await sut.extractText(from: imageData)

        // Assert
        XCTAssertFalse(extractedText.isEmpty, "Extracted text should not be empty")
        // Note: OCR might not be 100% accurate in test environments
        // We mainly verify that the service runs without errors
    }

    func testExtractTextFromEmptyImage() async throws {
        // Create a blank image
        let blankImage = createBlankImage()
        guard let imageData = imageData(from: blankImage) else {
            XCTFail("Failed to create blank image data")
            return
        }

        // Act & Assert
        do {
            let text = try await sut.extractText(from: imageData)
            // Blank image might return empty string or throw error
            XCTAssertTrue(text.isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } catch OCRError.noTextDetected {
            // This is also acceptable for blank images
            XCTAssertTrue(true)
        }
    }

    func testExtractTextFromInvalidData() async {
        // Create invalid image data
        let invalidData = Data([0x00, 0x01, 0x02])

        // Act & Assert
        do {
            _ = try await sut.extractText(from: invalidData)
            XCTFail("Should throw error for invalid image data")
        } catch OCRError.unsupportedImageFormat {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExtractTextFromURL() async throws {
        // Create a test image and save to temp directory
        let testImage = createTestImage(withText: "Invoice #12345")
        guard let imageData = imageData(from: testImage) else {
            XCTFail("Failed to create test image data")
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_invoice_\(UUID().uuidString).png")

        try imageData.write(to: tempURL)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        // Act
        let extractedText = try await sut.extractText(from: tempURL)

        // Assert
        XCTAssertFalse(extractedText.isEmpty)
    }

    // MARK: - Helper Methods

    private func createTestImage(withText text: String) -> PlatformImage {
        #if canImport(UIKit)
            return createUIImage(withText: text)
        #elseif canImport(AppKit)
            return createNSImage(withText: text)
        #endif
    }

    private func createBlankImage() -> PlatformImage {
        #if canImport(UIKit)
            return createUIImage(withText: "")
        #elseif canImport(AppKit)
            return createNSImage(withText: "")
        #endif
    }

    #if canImport(UIKit)
        private typealias PlatformImage = UIImage

        private func createUIImage(withText text: String) -> UIImage {
            let size = CGSize(width: 400, height: 300)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                // White background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                if !text.isEmpty {
                    // Draw text
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 24),
                        .foregroundColor: UIColor.black,
                    ]

                    let textRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
                    text.draw(in: textRect, withAttributes: attributes)
                }
            }
        }

        private func imageData(from image: UIImage) -> Data? {
            image.pngData()
        }

    #elseif canImport(AppKit)
        private typealias PlatformImage = NSImage

        private func createNSImage(withText text: String) -> NSImage {
            let size = CGSize(width: 400, height: 300)
            let image = NSImage(size: size)

            image.lockFocus()

            // White background
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()

            if !text.isEmpty {
                // Draw text
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 24),
                    .foregroundColor: NSColor.black,
                ]

                let textRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
                text.draw(in: textRect, withAttributes: attributes)
            }

            image.unlockFocus()

            return image
        }

        private func imageData(from image: NSImage) -> Data? {
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData)
            else {
                return nil
            }
            return bitmap.representation(using: .png, properties: [:])
        }
    #endif
}
