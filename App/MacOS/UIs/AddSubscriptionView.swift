import SwiftUI
import SmartSubscriptionKit
import UniformTypeIdentifiers

struct AddSubscriptionView: View {
    @StateObject var viewModel = AddSubscriptionViewModel()
    @Binding var path: NavigationPath
    
    // Dependencies
    let invoiceOCRUseCase: InvoiceOCRUseCase
    let subscriptionUseCase: SubscriptionUseCase

    var body: some View {
        VStack {
            // This view is primarily a coordinator/wrapper
            // It presents the initial choice via confirmationDialog
            Text("Select an option")
                .hidden()
        }
        .onAppear {
            viewModel.isShowingActionSheet = true
        }
        .confirmationDialog("Add Subscription", isPresented: $viewModel.isShowingActionSheet) {
            Button("Scan Invoice") {
                // In a real app, this would open camera. For macOS, we'll use file importer as fallback/mock
                // or assume user has a file to "scan"
                viewModel.isShowingImagePicker = true
            }
            Button("Upload Image") {
                viewModel.isShowingImagePicker = true
            }
            Button("Manual Entry") {
                path.append(NavigationRoute.reviewSubscription(nil))
            }
            Button("Cancel", role: .cancel) {
                if path.count > 0 {
                    path.removeLast()
                }
            }
        } message: {
            Text("Choose how you want to add a subscription")
        }
        .fileImporter(
            isPresented: $viewModel.isShowingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    path.append(NavigationRoute.ocrProcessing(url))
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}
