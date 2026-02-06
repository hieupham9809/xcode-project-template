import SwiftUI
import SmartSubscriptionKit
import AVFoundation
import Photos

struct AddSubscriptionView: View {
    @StateObject var viewModel = AddSubscriptionViewModel()
    @Binding var path: NavigationPath

    // Dependencies
    let invoiceOCRUseCase: InvoiceOCRUseCase
    let subscriptionUseCase: SubscriptionUseCase

    // State
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageURL: URL?
    @State private var showingPermissionAlert = false
    @State private var permissionAlertType: PermissionType?

    enum PermissionType {
        case camera, photoLibrary

        var title: String {
            switch self {
            case .camera: return "Camera Access Required"
            case .photoLibrary: return "Photo Library Access Required"
            }
        }

        var message: String {
            switch self {
            case .camera: return "Please allow camera access in Settings to scan invoices."
            case .photoLibrary: return "Please allow photo library access in Settings to upload invoices."
            }
        }
    }

    var body: some View {
        VStack {
            Text("Select an option")
                .hidden()
        }
        .onAppear {
            viewModel.isShowingActionSheet = true
        }
        .confirmationDialog("Add Subscription", isPresented: $viewModel.isShowingActionSheet) {
            Button("Scan Invoice") {
                Task {
                    await handleCameraRequest()
                }
            }
            Button("Upload Image") {
                Task {
                    await handlePhotoLibraryRequest()
                }
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
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(selectedImageURL: $selectedImageURL)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(selectedImageURL: $selectedImageURL)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImageURL) { url in
            if let url {
                path.append(NavigationRoute.ocrProcessing(url))
                selectedImageURL = nil
            }
        }
        .alert(
            permissionAlertType?.title ?? "Permission Required",
            isPresented: $showingPermissionAlert
        ) {
            Button("Open Settings") {
                PermissionManager.shared.openSettings()
            }
            Button("Cancel", role: .cancel) {
                if path.count > 0 {
                    path.removeLast()
                }
            }
        } message: {
            Text(permissionAlertType?.message ?? "")
        }
    }

    @MainActor
    private func handleCameraRequest() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            let granted = await PermissionManager.shared.requestCameraPermission()
            if granted {
                showingCamera = true
            } else {
                permissionAlertType = .camera
                showingPermissionAlert = true
            }
        case .denied, .restricted:
            permissionAlertType = .camera
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }

    @MainActor
    private func handlePhotoLibraryRequest() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            showingImagePicker = true
        case .notDetermined:
            let granted = await PermissionManager.shared.requestPhotoLibraryPermission()
            if granted {
                showingImagePicker = true
            } else {
                permissionAlertType = .photoLibrary
                showingPermissionAlert = true
            }
        case .denied, .restricted:
            permissionAlertType = .photoLibrary
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
}
