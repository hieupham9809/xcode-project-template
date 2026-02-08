import Foundation
#if canImport(UIKit)
    import UIKit
#endif
#if canImport(AppKit)
    import AppKit
#endif

public actor OpenAIVisionParser: InvoiceParser {
    private let session: URLSession
    private let settingsStore: SettingsStore
    private let logger = Log.initialize(category: .main)

    public init(session: URLSession = .shared, settingsStore: SettingsStore = .shared) {
        self.session = session
        self.settingsStore = settingsStore
    }

    public func parse(imageURL: URL) async throws -> Invoice {
        guard let data = try? Data(contentsOf: imageURL) else {
            throw InvoiceParserError.invalidImage
        }
        return try await parse(imageData: data)
    }

    public func parse(imageData: Data) async throws -> Invoice {
        guard let apiKey = settingsStore.openAIAPIKey else {
            throw InvoiceParserError.noAPIKey
        }

        // Resize image to reduce tokens (max 1024px on longest side)
        let resizedData = resizeImageIfNeeded(imageData, maxDimension: 1024)
        logger.debug("[InvoiceParser] Original size: \(imageData.count) bytes, Resized: \(resizedData.count) bytes")

        let base64Image = resizedData.base64EncodedString()

        let systemPrompt = """
        You are an expert OCR and invoice parsing assistant.
        Extract the following fields from the invoice image:
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
                    "content": [
                        [
                            "type": "text",
                            "text": "Parse this invoice.",
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                            ],
                        ],
                    ],
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

        return try parseOpenAIResponse(data)
    }

    private func performRequestWithRetry(_ request: URLRequest, attempt: Int = 1) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            if attempt < 3 {
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
                return try await performRequestWithRetry(request, attempt: attempt + 1)
            }
            throw InvoiceParserError.networkError(error.localizedDescription)
        }
    }

    private func parseOpenAIResponse(_ data: Data) throws -> Invoice {
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

        logger.debug("[InvoiceParser] Raw API response content: \(content)")

        // Clean up markdown code blocks if present
        let cleanContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        logger.debug("[InvoiceParser] Cleaned content: \(cleanContent)")

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

        logger.debug("[InvoiceParser] Parsed providerName: \(parsed.providerName)")
        logger.debug("[InvoiceParser] Parsed totalAmount: \(parsed.totalAmount) \(parsed.currencyCode)")
        logger.debug("[InvoiceParser] Parsed invoiceDate: \(parsed.invoiceDate)")

        // Date parsing
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: parsed.invoiceDate) ?? Date()

        let totalMoney = Money(amount: parsed.totalAmount, currencyCode: parsed.currencyCode)
        let domainLineItems = parsed.lineItems.map {
            Invoice.LineItem(title: $0.title, amount: Money(amount: $0.amount, currencyCode: parsed.currencyCode))
        }

        // Note: We return an Invoice, but we need to associate it with a Subscription.
        // Since the parser doesn't know about existing subscriptions or which one this belongs to,
        // we'll return a temporary Invoice with a dummy subscription ID.
        // The calling UseCase/ViewModel should handle linking or creating a new Subscription.

        // However, we also need to return the providerName to help with subscription matching.
        // We might need to extend Invoice or return a Tuple/Wrapper.
        // For now, let's assume we create a new Subscription for it or match it later.
        // We will store the providerName in the Invoice's ocrText for now as a JSON string or just return the Invoice
        // and let the caller handle the rest.
        // Wait, Invoice doesn't have providerName. Subscription does.
        // Let's assume we return an Invoice that has the parsed data.

        // Actually, for "Add Subscription" flow, we parse an image and want to populate the "Add Subscription" form.
        // That form needs: Name (Provider), Amount, Date, etc.
        // The Invoice model has: invoiceDate, total, lineItems.
        // It seems we might want a specific `ParsedInvoiceResult` struct that includes provider name.

        // Let's modify the return type? No, the protocol says `Invoice`.
        // But `Invoice` is strictly linked to a `Subscription`.
        // Maybe we should update `Invoice` to include `providerName` optionally? Or use a separate DTO?
        // Given the protocol `func parse(...) -> Invoice`, we are constrained.
        // Let's stick to returning an Invoice, and maybe embed the provider name in `ocrText` temporarily?
        // Or better: The caller probably wants a `Subscription` AND an `Invoice`.

        // Let's look at `Invoice` struct again.
        // It has `ocrText`. We can put the full raw JSON in `ocrText`.

        return Invoice(
            subscriptionID: Subscription.ID(), // Temporary
            invoiceDate: date,
            total: totalMoney,
            lineItems: domainLineItems,
            ocrText: cleanContent // Store raw JSON for caller to extract providerName
        )
    }

    private func resizeImageIfNeeded(_ data: Data, maxDimension: CGFloat) -> Data {
        #if canImport(UIKit)
            guard let image = UIImage(data: data) else { return data }

            // Calculate new size
            let size = image.size
            let aspectRatio = size.width / size.height
            var newSize = size

            if size.width > maxDimension || size.height > maxDimension {
                if size.width > size.height {
                    newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                }

                let renderer = UIGraphicsImageRenderer(size: newSize)
                let resizedImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }

                return resizedImage.jpegData(compressionQuality: 0.8) ?? data
            }
            return data
        #else
            // For macOS (if needed later), or just return original data
            return data
        #endif
    }
}
