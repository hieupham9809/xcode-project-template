import Foundation

/// Parsing mode for invoice processing
public enum ParserMode: String, Codable, CaseIterable, Sendable {
    /// Standard mode: sends image directly to OpenAI Vision API
    case normal = "Normal"

    /// Optimizing mode: uses on-device OCR, then sends text to OpenAI (saves tokens)
    case optimizing = "Optimizing"

    /// Display name for UI
    public var displayName: String {
        rawValue
    }

    /// Detailed description of the mode
    public var description: String {
        switch self {
        case .normal:
            "Sends image directly to OpenAI Vision API"
        case .optimizing:
            "Uses on-device OCR, then sends text to OpenAI (saves tokens)"
        }
    }

    /// Extended description with benefits
    public var detailedDescription: String {
        switch self {
        case .normal:
            """
            Standard mode sends the full image to OpenAI's Vision API for processing. \
            This mode provides reliable results but uses more tokens and may be slower \
            for large images.
            """
        case .optimizing:
            """
            Optimizing mode first extracts text from the image using on-device Apple Vision, \
            then sends only the text to OpenAI. This reduces token usage by ~60-70%, \
            speeds up processing, and keeps OCR processing private on your device.
            """
        }
    }

    /// Token usage estimate relative to normal mode
    public var tokenSavings: String {
        switch self {
        case .normal:
            "0%"
        case .optimizing:
            "~60-70%"
        }
    }
}

/// Factory for creating invoice parsers based on the selected mode
public struct ParserFactory: Sendable {
    public init() {}

    /// Create an appropriate parser based on the selected mode
    /// - Parameters:
    ///   - mode: The parsing mode to use
    ///   - settingsStore: Settings store for API keys and configuration
    ///   - session: URLSession for network requests (default: .shared)
    /// - Returns: An InvoiceParser instance configured for the selected mode
    public func createParser(
        mode: ParserMode,
        settingsStore: SettingsStore = .shared,
        session: URLSession = .shared
    ) -> InvoiceParser {
        switch mode {
        case .normal:
            return OpenAIVisionParser(session: session, settingsStore: settingsStore)

        case .optimizing:
            let ocrService = AppleVisionOCRService()
            let textParser = OpenAITextParser(session: session, settingsStore: settingsStore)
            return OptimizingInvoiceParser(ocrService: ocrService, textParser: textParser)
        }
    }

    /// Convenience method to create parser from settings store's current mode
    /// - Parameters:
    ///   - settingsStore: Settings store that contains the current parser mode
    ///   - session: URLSession for network requests (default: .shared)
    /// - Returns: An InvoiceParser instance configured based on current settings
    public func createParser(
        from settingsStore: SettingsStore = .shared,
        session: URLSession = .shared
    ) -> InvoiceParser {
        createParser(
            mode: settingsStore.parserMode,
            settingsStore: settingsStore,
            session: session
        )
    }
}
