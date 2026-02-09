import SwiftUI
import SmartSubscriptionKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct OCRProcessingView: View {
    let imageURL: URL?
    @StateObject var viewModel: OCRProcessingViewModel
    let onCompletion: (Invoice) -> Void
    
    // Animation state
    @State private var isScanning = false
    
    init(
        imageURL: URL?,
        viewModel: OCRProcessingViewModel,
        onCompletion: @escaping (Invoice) -> Void
    ) {
        self.imageURL = imageURL
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onCompletion = onCompletion
    }

    var body: some View {
        ZStack {
            // Background Image (Blurred)
            Color.appPrimaryBackground.ignoresSafeArea()
            
            if let url = imageURL {
                #if os(macOS)
                if let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 20)
                        .opacity(0.3)
                        .ignoresSafeArea()
                }
                #else
                if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 20)
                        .opacity(0.3)
                        .ignoresSafeArea()
                }
                #endif
            }

            VStack(spacing: 32) {
                // Scanning Animation Container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder, lineWidth: 1)
                        .frame(width: 280, height: 380)
                        .background(Color.appElevatedBackground.opacity(0.5))
                    
                    if let url = imageURL {
                        #if os(macOS)
                        if let nsImage = NSImage(contentsOf: url) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 260, height: 360)
                                .cornerRadius(12)
                                .opacity(0.8)
                        }
                        #else
                        if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 260, height: 360)
                                .cornerRadius(12)
                                .opacity(0.8)
                        }
                        #endif
                    }
                    
                    // Scanning Beam
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.appAccent.opacity(0.5),
                                    Color.appAccent,
                                    Color.appAccent.opacity(0.5),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 280, height: 4)
                        .offset(y: isScanning ? 180 : -180)
                        .animation(
                            Animation.linear(duration: 2.0).repeatForever(autoreverses: true),
                            value: isScanning
                        )
                }
                .onAppear {
                    isScanning = true
                }

                // Status & Progress
                VStack(spacing: 12) {
                    Text(viewModel.statusText)
                        .font(.headline)
                        .foregroundStyle(Color.appPrimaryText)
                        .transition(.opacity)
                        .id(viewModel.statusText) // Force animation on text change

                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.appAccent))
                        .frame(width: 200)
                }
            
                // Success Overlay (Manual control if needed)
                if let invoice = viewModel.scannedInvoice {
                    ZStack {
                        Color.appOverlay.ignoresSafeArea()

                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.appSuccess)
                                .padding(.bottom, 10)

                            Text("Scan Complete")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(Color.appPrimaryText)

                            HStack(spacing: 16) {
                                Button("Retake") {
                                    Task {
                                        viewModel.scannedInvoice = nil
                                        await viewModel.processImage(url: imageURL!)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(Color.appBrandPrimary)

                                Button("Continue") {
                                    onCompletion(invoice)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.appAccent)
                            }
                        }
                        .padding(30)
                        .background(Color.appElevatedBackground)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                    }
                }
            }
            
            // Error Overlay
            if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appError)
                    Text("Scanning Failed")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color.appPrimaryText)
                    Text(error)
                        .font(.body)
                        .foregroundStyle(Color.appSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Try Again") {
                        if let url = imageURL {
                            Task {
                                await viewModel.processImage(url: url)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appAccent)
                }
                .padding()
                .background(Color.appElevatedBackground)
                .cornerRadius(16)
                .shadow(color: Color.appShadow, radius: 10)
                .padding(40)
            }
        }
        .task {
            if let url = imageURL {
                await viewModel.processImage(url: url)
            }
        }
        .onChange(of: viewModel.scannedInvoice) { invoice in
            if let invoice = invoice {
                onCompletion(invoice)
            }
        }
    }
}
