//
//  AppTemplateIAPPageSheet.swift
//
//
//  Created by Harley Pham on 25/8/24.
//

import Foundation
import SwiftUI

public struct AppTemplateIAPPageSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel = AppTemplateIAPPageSheetViewModel()

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Text("Support us")
                .foregroundStyle(Color.primaryText)
                .fontWithPadding(.systemFont(ofSize: 18, weight: .regular), padding: 4)
        }
        .buttonStyle(SupportPlainButtonStyle(backgroundColor: Color(hex: 0xD0F5FF)))
        .sheet(isPresented: $isPresented) {
            donationView
        }
    }
    
    private var donationView: some View {
        VStack {
            switch viewModel.purchaseStatus {
            case .none:
                donationOptionsView
            case .failed:
                failedView
            case .success:
                successView
            case .loading:
                loadingView
            }
        }
        .frame(width: 400, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 8).fill(Color.white)
        )
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    @ViewBuilder
    private var donationOptionsView: some View {
        HStack {
            Spacer()
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .resizable()
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 18, height: 18)
                    .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        Text("Select an item to support us!")
            .foregroundStyle(Color.primaryText)
            .fontWithPadding(.systemFont(ofSize: 32, weight: .bold), padding: 4)
            .padding(.top, 24)

        if viewModel.iapItems.isEmpty {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .padding(16)
        }
        else {
            List(viewModel.iapItems) { item in
                Button(action: {
                    viewModel.onSelect(iapItem: item)
                }) {
                    HStack {
                        Text(item.icon)
                            .foregroundStyle(Color.primaryText)
                        Text(item.title)
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Text(item.price)
                            .foregroundStyle(Color.primaryText)

                    }
                    .fontWithPadding(.systemFont(ofSize: 24, weight: .regular), padding: 4)
                    .padding(16)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .alert(
                "Confirm purchase",
                isPresented: .init(get: {
                    viewModel.confirmPurchaseAlertItem != nil
                }, set: { _ in
                    viewModel.confirmPurchaseAlertItem = nil
                })
            ) {
                Button("Cancel", role: .cancel) {
                    viewModel.confirmPurchaseAlertItem = nil
                }
                Button("Confirm") {
                    if let item = viewModel.confirmPurchaseAlertItem {
                        viewModel.onConfirmPurchase(iapItem: item)
                        viewModel.confirmPurchaseAlertItem = nil
                    }
                }
            }
        }

        Spacer()
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .padding(16)
        Text("Processing your purchase...")
            .foregroundStyle(Color.primaryText)
            .fontWithPadding(.systemFont(ofSize: 24, weight: .bold), padding: 4)
    }
    
    @ViewBuilder
    private var successView: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(Color.AppTemplateMainGradient)
            .padding(16)
        Text("Thank you for your support!")
            .foregroundStyle(Color.primaryText)
            .fontWithPadding(.systemFont(ofSize: 24, weight: .bold), padding: 4)
        Button(action: {
            viewModel.onCompletePurchase()
            isPresented = false
        }) {
            Text("OK")
                .padding(.horizontal, 32)
                .foregroundStyle(Color.primaryText)
                .fontWithPadding(.systemFont(ofSize: 18, weight: .regular), padding: 4)
        }
        .buttonStyle(SupportPlainButtonStyle(backgroundColor: Color(hex: 0xD0F5FF)))
        .padding(16)
    }
    
    @ViewBuilder
    private var failedView: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(Color.gray)
            .padding(16)
        Text("Failed to process your purchase. Please try again later.")
            .foregroundStyle(Color.primaryText)
            .fontWithPadding(.systemFont(ofSize: 24, weight: .bold), padding: 4)
        
        Button(action: {
            viewModel.onTryAgain()
        }) {
            Text("Try again")
                .foregroundStyle(Color.primaryText)
                .fontWithPadding(.systemFont(ofSize: 18, weight: .regular), padding: 4)
        }
        .buttonStyle(SupportPlainButtonStyle(backgroundColor: Color(hex: 0xD0F5FF)))
        .padding(16)
    }
}

struct SupportPlainButtonStyle: ButtonStyle {
    let backgroundColor: Color
    @State var isHovering: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .brightness(isHovering ? -0.1 : 0)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? .white.opacity(0.2) : .clear)
            )
            .onContinuousHover { hover in
                switch hover {
                case .active:
                    isHovering = true
                case .ended:
                    isHovering = false
                }
            }
    }
}
