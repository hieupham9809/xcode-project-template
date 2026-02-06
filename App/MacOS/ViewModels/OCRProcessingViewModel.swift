import Foundation
import SmartSubscriptionKit
import Combine
import SwiftUI

@MainActor
final class OCRProcessingViewModel: ObservableObject {
    @Published var statusText: String = "Initializing..."
    @Published var progress: Double = 0.0
    @Published var scannedInvoice: Invoice?
    @Published var error: String?
    @Published var isProcessing: Bool = false
    
    private let invoiceOCRUseCase: InvoiceOCRUseCase
    private var timer: AnyCancellable?

    init(invoiceOCRUseCase: InvoiceOCRUseCase) {
        self.invoiceOCRUseCase = invoiceOCRUseCase
    }

    func processImage(url: URL) async {
        // Prevent re-processing if we already have a result or are processing
        if scannedInvoice != nil || isProcessing {
            return
        }
        
        isProcessing = true
        error = nil
        startSimulatedProgress()
        
        do {
            let invoice = try await invoiceOCRUseCase.parseInvoice(from: url)
            stopSimulatedProgress()
            statusText = "Complete!"
            progress = 1.0
            // Slight delay to show completion
            try await Task.sleep(nanoseconds: 500_000_000)
            scannedInvoice = invoice
        } catch {
            stopSimulatedProgress()
            self.error = error.localizedDescription
            self.statusText = "Failed"
        }
        isProcessing = false
    }

    private func startSimulatedProgress() {
        progress = 0.0
        let statusMessages = [
            "Connecting to AI...",
            "Uploading image...",
            "Scanning document...",
            "Extracting dates...",
            "Identifying prices...",
            "Finalizing..."
        ]
        
        var msgIndex = 0
        
        timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.progress < 0.9 {
                    self.progress += 0.05
                }
                
                if msgIndex < statusMessages.count && Int(self.progress * 10) % 2 == 0 {
                    self.statusText = statusMessages[msgIndex]
                    msgIndex = (msgIndex + 1) % statusMessages.count
                }
            }
    }

    private func stopSimulatedProgress() {
        timer?.cancel()
        timer = nil
    }
}
