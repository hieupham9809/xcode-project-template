import Foundation

/// Errors that can occur during OCR processing
public enum OCRError: LocalizedError {
    case visionFrameworkUnavailable
    case noTextDetected
    case imageProcessingFailed(String)
    case unsupportedImageFormat
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .visionFrameworkUnavailable:
            "Vision Framework is not available on this device"
        case .noTextDetected:
            "No text detected in image"
        case let .imageProcessingFailed(reason):
            "Image processing failed: \(reason)"
        case .unsupportedImageFormat:
            "Unsupported image format"
        case .invalidImageData:
            "Invalid image data"
        }
    }
}

/// Protocol for optical character recognition (OCR) services
/// Extracts text from images using various OCR engines
public protocol OCRService: Sendable {
    /// Extract text from an image file
    /// - Parameter imageURL: URL to the image file
    /// - Returns: Extracted text with preserved structure
    /// - Throws: OCRError if extraction fails
    func extractText(from imageURL: URL) async throws -> String

    /// Extract text from image data
    /// - Parameter imageData: Raw image data
    /// - Returns: Extracted text with preserved structure
    /// - Throws: OCRError if extraction fails
    func extractText(from imageData: Data) async throws -> String
}
