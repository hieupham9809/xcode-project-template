import Foundation

/// Parser that extracts structured invoice data from OCR-extracted text using OpenAI API
/// This parser is optimized for token efficiency by working with text instead of images
public actor OpenAITextParser: Sendable {
    private let session: URLSession
    private let settingsStore: SettingsStore
    private let logger = Log.initialize(category: .main)

    public init(session: URLSession = .shared, settingsStore: SettingsStore = .shared) {
        self.session = session
        self.settingsStore = settingsStore
    }

    /// Parse invoice data from OCR-extracted text
    /// - Parameter text: The text extracted from an invoice image via OCR
    /// - Returns: Parsed Invoice object
    /// - Throws: InvoiceParserError if parsing fails
    public func parseInvoiceFromText(_ text: String) async throws -> Invoice {
        guard let apiKey = settingsStore.openAIAPIKey else {
            throw InvoiceParserError.noAPIKey
        }

        logger.debug("[OpenAITextParser] Parsing invoice from \(text.count) characters of text")

        let systemPrompt = """
        You are an expert invoice parsing assistant.
        You will receive text that was extracted from an invoice image via OCR.
        Extract the following fields from the invoice text:
        - Invoice Date (ISO 8601 format YYYY-MM-DD)
        - Total Amount (numeric, see NUMBER FORMAT RULES below)
        - Currency Code (3-letter ISO code, e.g. USD, EUR, VND, JPY)
        - Subscription Name (descriptive name including plan/tier, e.g., "Netflix Premium", "Spotify Family")
        - Vendor/Provider Name (company name only, e.g., "Netflix", "Spotify")
        - Billing Cycle (one of: "weekly", "monthly", "yearly"). Infer this from the invoice context (e.g., "Monthly subscription", "Yearly plan", "Billed every month"). If unknown, omit.
        - Line Items (title and amount)

        CONTEXT:
        - Current system date: \(Date().formatted(date: .numeric, time: .omitted))

        NUMBER FORMAT RULES (Excel Standard):
        - Use PERIOD (.) as the decimal separator
        - Commas in numbers are THOUSANDS separators, NOT decimals
        - "268,129" means 268129 (two hundred sixty-eight thousand one hundred twenty-nine)
        - "1,234.56" means 1234.56 (one thousand two hundred thirty-four and 56 cents)

        ZERO-DECIMAL CURRENCIES (no decimal places):
        - VND (Vietnamese Dong), JPY (Japanese Yen), KRW (Korean Won), IDR (Indonesian Rupiah)
        - For these currencies, amounts are always whole numbers (e.g., 268129 VND, not 268.13 VND)

        SANITY CHECK - Apply reasoning based on currency context:
        - A Netflix subscription in VND for "268.13" doesn't make sense (too small ~$0.01 USD)
        - It should be "268129" VND (~$10.70 USD) which is a reasonable subscription price
        - Compare the parsed amount against typical USD equivalent values ($5-$100 for subscriptions)
        - If the amount seems unreasonably small or large, reconsider the number format interpretation

        Return ONLY a valid JSON object with this schema:
        {
          "invoiceDate": "YYYY-MM-DD",
          "totalAmount": 268129,
          "currencyCode": "VND",
          "subscriptionName": "Service Plan Name",
          "providerName": "Vendor Name",
          "billingCycle": "monthly",
          "lineItems": [
            { "title": "Item 1", "amount": 150000 },
            { "title": "Item 2", "amount": 118129 }
          ]
        }
        If subscriptionName is not clearly stated, use providerName as fallback.
        If a field is missing, make a best guess or omit it. Ensure the JSON is valid.
        """

        let requestBody: [String: Any] = [
            "model": settingsStore.selectedModel,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt,
                ],
                [
                    "role": "user",
                    "content": "Parse this invoice:\n\n\(text)",
                ],
            ],
            "max_tokens": 1000,
        ]

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await performRequestWithRetry(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InvoiceParserError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw InvoiceParserError.unauthorized
            } else if httpResponse.statusCode == 429 {
                throw InvoiceParserError.rateLimited
            }
            throw InvoiceParserError.networkError("Status code: \(httpResponse.statusCode)")
        }

        return try parseOpenAIResponse(data, originalText: text)
    }

    // MARK: - Private Helpers

    private func performRequestWithRetry(_ request: URLRequest, attempt: Int = 1) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            if attempt < 3 {
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                logger.debug("[OpenAITextParser] Retry attempt \(attempt) after \(delay / 1_000_000_000)s")
                try await Task.sleep(nanoseconds: delay)
                return try await performRequestWithRetry(request, attempt: attempt + 1)
            }
            throw InvoiceParserError.networkError(error.localizedDescription)
        }
    }

    private func parseOpenAIResponse(_ data: Data, originalText: String) throws -> Invoice {
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }

                let message: Message
            }

            let choices: [Choice]
        }

        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw InvoiceParserError.parsingFailed("No content in response")
        }

        logger.debug("[OpenAITextParser] Raw API response content: \(content)")

        // Clean up markdown code blocks if present
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        logger.debug("[OpenAITextParser] Cleaned content: \(cleanContent)")

        guard let jsonData = cleanContent.data(using: .utf8) else {
            throw InvoiceParserError.parsingFailed("Invalid string data")
        }

        struct ParsedInvoice: Decodable {
            let invoiceDate: String
            let totalAmount: Decimal
            let currencyCode: String
            let subscriptionName: String?
            let providerName: String
            let billingCycle: String?
            struct LineItem: Decodable {
                let title: String
                let amount: Decimal
            }

            let lineItems: [LineItem]
        }

        let parsed = try JSONDecoder().decode(ParsedInvoice.self, from: jsonData)
        logger.debug("[OpenAITextParser] original text: \(originalText)")
        logger.debug("[OpenAITextParser] Parsed providerName: \(parsed.providerName)")
        logger.debug("[OpenAITextParser] Parsed totalAmount: \(parsed.totalAmount) \(parsed.currencyCode)")
        logger.debug("[OpenAITextParser] Parsed invoiceDate: \(parsed.invoiceDate)")

        // Date parsing
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: parsed.invoiceDate) ?? Date()

        let totalMoney = Money(amount: parsed.totalAmount, currencyCode: parsed.currencyCode)
        let domainLineItems = parsed.lineItems.map {
            Invoice.LineItem(title: $0.title, amount: Money(amount: $0.amount, currencyCode: parsed.currencyCode))
        }

        // Store the original OCR text and parsed JSON for debugging/reference

        return Invoice(
            subscriptionID: Subscription.ID(), // Temporary
            invoiceDate: date,
            total: totalMoney,
            lineItems: domainLineItems,
            ocrText: cleanContent
        )
    }
}
