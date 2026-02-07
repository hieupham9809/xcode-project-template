import Foundation

/// Optimized invoice parser that uses on-device OCR before sending text to OpenAI
/// This approach reduces token usage and API costs compared to sending full images
public actor OptimizingInvoiceParser: InvoiceParser {
    private let ocrService: OCRService
    private let textParser: OpenAITextParser
    private let logger = Log.initialize(category: .main)

    public init(
        ocrService: OCRService = AppleVisionOCRService(),
        textParser: OpenAITextParser = OpenAITextParser()
    ) {
        self.ocrService = ocrService
        self.textParser = textParser
    }

    public func parse(imageURL: URL) async throws -> Invoice {
        logger.debug("[OptimizingParser] Starting optimized parsing for image at: \(imageURL.path)")

        do {
            // Step 1: Extract text using on-device OCR
            logger.debug("[OptimizingParser] Step 1: Extracting text with Apple Vision")
            let extractedText = try await ocrService.extractText(from: imageURL)

            guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.warning("[OptimizingParser] OCR extracted empty text")
                throw InvoiceParserError.parsingFailed("No text extracted from image")
            }

            logger.debug("[OptimizingParser] OCR extracted \(extractedText.count) characters")

            // Step 2: Parse invoice data from extracted text
            logger.debug("[OptimizingParser] Step 2: Parsing invoice data with OpenAI")
            var invoice = try await textParser.parseInvoiceFromText(extractedText)

            // Step 3: Associate the source image URL
            invoice = Invoice(
                id: invoice.id,
                subscriptionID: invoice.subscriptionID,
                invoiceDate: invoice.invoiceDate,
                total: invoice.total,
                lineItems: invoice.lineItems,
                sourceImageURL: imageURL,
                ocrText: invoice.ocrText,
                createdAt: invoice.createdAt
            )

            logger.debug("[OptimizingParser] Successfully parsed invoice")
            return invoice

        } catch let error as OCRError {
            logger.error("[OptimizingParser] OCR failed: \(error.localizedDescription)")
            throw InvoiceParserError.ocrFailed(error)
        } catch let error as InvoiceParserError {
            logger.error("[OptimizingParser] Parsing failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("[OptimizingParser] Unexpected error: \(error.localizedDescription)")
            throw InvoiceParserError.parsingFailed(error.localizedDescription)
        }
    }

    public func parse(imageData: Data) async throws -> Invoice {
        logger.debug("[OptimizingParser] Starting optimized parsing for image data (\(imageData.count) bytes)")

        do {
            // Step 1: Extract text using on-device OCR
            logger.debug("[OptimizingParser] Step 1: Extracting text with Apple Vision")
            let extractedText = try await ocrService.extractText(from: imageData)

            guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                logger.warning("[OptimizingParser] OCR extracted empty text")
                throw InvoiceParserError.parsingFailed("No text extracted from image")
            }

            logger.debug("[OptimizingParser] OCR extracted \(extractedText.count) characters")

            // Step 2: Parse invoice data from extracted text
            logger.debug("[OptimizingParser] Step 2: Parsing invoice data with OpenAI")
            let invoice = try await textParser.parseInvoiceFromText(extractedText)

            logger.debug("[OptimizingParser] Successfully parsed invoice")
            return invoice

        } catch let error as OCRError {
            logger.error("[OptimizingParser] OCR failed: \(error.localizedDescription)")
            throw InvoiceParserError.ocrFailed(error)
        } catch let error as InvoiceParserError {
            logger.error("[OptimizingParser] Parsing failed: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("[OptimizingParser] Unexpected error: \(error.localizedDescription)")
            throw InvoiceParserError.parsingFailed(error.localizedDescription)
        }
    }
}
