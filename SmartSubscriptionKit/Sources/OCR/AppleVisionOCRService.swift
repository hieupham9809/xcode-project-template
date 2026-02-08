import Foundation
import Vision

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// OCR service implementation using Apple's Vision Framework
/// Uses RecognizeDocumentsRequest (iOS 18+/macOS 15+) for structured text extraction
/// Falls back to RecognizeTextRequest on older OS versions
public actor AppleVisionOCRService: OCRService {
    private let logger = Log.initialize(category: .main)

    public init() {}

    public func extractText(from imageURL: URL) async throws -> String {
        guard let data = try? Data(contentsOf: imageURL) else {
            throw OCRError.invalidImageData
        }
        return try await extractText(from: data)
    }

    public func extractText(from imageData: Data) async throws -> String {
        // Convert data to CGImage
        guard let cgImage = createCGImage(from: imageData) else {
            throw OCRError.unsupportedImageFormat
        }

        // Perform OCR based on OS version
//        if #available(iOS 26.0, macOS 15.0, *) {
//            return try await extractTextWithDocumentRecognition(cgImage: cgImage)
//        } else {
        return try await extractTextWithBasicRecognition(cgImage: cgImage)
//        }
    }

    // MARK: - iOS 18+ / macOS 15+ Implementation (Structured Document Recognition)

//    @available(iOS 26.0, macOS 15.0, *)
//    private func extractTextWithDocumentRecognition(cgImage: CGImage) async throws -> String {
//        var request = RecognizeDocumentsRequest()
//
//        // Enable language correction to fix OCR errors (e.g., '0' vs 'O')
//        request.textRecognitionOptions.useLanguageCorrection = true
//
//        // Create image request handler
//        let handler = ImageRequestHandler(cgImage)
//
//        logger.debug("[OCR] Using RecognizeDocumentsRequest for structured text extraction")
//
//        do {
//            // Perform the request using async/await
//            let observations = try await handler.perform(request)
//
//            // Process the results
//            guard let document = observations.first?.document else {
//                logger.warning("[OCR] No document structure detected")
//                throw OCRError.noTextDetected
//            }
//
//            // Build formatted text from paragraphs to preserve structure
//            var fullText = ""
//            for paragraph in document.paragraphs {
//                fullText += paragraph.transcript + "\n"
//            }
//
//            guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//                throw OCRError.noTextDetected
//            }
//
//            logger.debug("[OCR] Successfully extracted \(fullText.count) characters")
//            return fullText
//        } catch let error as OCRError {
//            throw error
//        } catch {
//            logger.error("[OCR] Document recognition failed: \(error.localizedDescription)")
//            throw OCRError.imageProcessingFailed(error.localizedDescription)
//        }
//    }

    // MARK: - iOS 16+ / macOS 13+ Fallback (Basic Text Recognition)

    private func extractTextWithBasicRecognition(cgImage: CGImage) async throws -> String {
        let request = VNRecognizeTextRequest()

        // Configure for accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        logger.debug("[OCR] Using VNRecognizeTextRequest for basic text extraction")

        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])

                guard let observations = request.results, !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextDetected)
                    return
                }

                // Combine all recognized text
                var fullText = ""
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    fullText += topCandidate.string + "\n"
                }

                guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continuation.resume(throwing: OCRError.noTextDetected)
                    return
                }

                logger.debug("[OCR] Successfully extracted \(fullText.count) characters (basic mode)")
                continuation.resume(returning: fullText)
            } catch {
                logger.error("[OCR] Basic text recognition failed: \(error.localizedDescription)")
                continuation.resume(throwing: OCRError.imageProcessingFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Image Processing Helpers

    private func createCGImage(from data: Data) -> CGImage? {
        #if canImport(UIKit)
            guard let image = UIImage(data: data) else { return nil }
            return image.cgImage
        #elseif canImport(AppKit)
            guard let image = NSImage(data: data) else { return nil }
            var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            return image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        #else
            return nil
        #endif
    }
}
