//
//  ContentView.swift
//  SmartSubscription
//
//  Created by Harley Pham on 18/05/2024.
//

import SmartSubscriptionKit
import Foundation
import os
import SwiftUI
import AppKit

private let logger = Logger(subsystem: "SmartSubscription", category: "ContentView")

public struct ContentView: View {
    @Binding var path: NavigationPath
    private var viewModel: ContentViewModel
    @StateObject private var homeViewModel: HomeDashboardViewModel
    @State private var appearanceMode: AppearanceMode = SettingsStore.shared.appearanceMode

    init(
        path: Binding<NavigationPath>,
        viewModel: ContentViewModel
    ) {
        self._path = path
        self.viewModel = viewModel
        self._homeViewModel = StateObject(wrappedValue: HomeDashboardViewModel(
            subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
            categoryUseCase: SmartSubscriptionAppModel.shared.categoryUseCase
        ))
    }

    public var body: some View {
        NavigationStack(path: $path) {
            HomeDashboardView(viewModel: homeViewModel, path: $path)
                .navigationDestination(for: NavigationRoute.self) { route in
                    switch route {
                    case .addSubscription:
                        AddSubscriptionView(
                            path: $path,
                            invoiceOCRUseCase: SmartSubscriptionAppModel.shared.invoiceOCRUseCase,
                            subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase
                        )
                    case .ocrProcessing(let url):
                        OCRProcessingView(
                            imageURL: url,
                            viewModel: OCRProcessingViewModel(
                                invoiceOCRUseCase: SmartSubscriptionAppModel.shared.invoiceOCRUseCase
                            ),
                            onCompletion: { invoice in
                                // Pop OCR and push Review
                                // Note: Popping is async, so we might need to handle this carefully
                                // For simplicity, let's append.
                                path.append(NavigationRoute.reviewSubscription(invoice))
                            }
                        )
                    case .reviewSubscription(let invoice):
                        ReviewEditSubscriptionView(
                            viewModel: ReviewEditViewModel(
                                subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
                                invoice: invoice
                            )
                        )
                    case .subscriptionDetail(let id):
                        // We need to fetch the subscription object. 
                        // For MVP, passing ID and fetching in VM is cleaner.
                        // But we need to find it first from the list or repo.
                        // Let's assume we can pass the object or ID.
                        // Wait, HomeViewModel has the list. 
                        // Let's modify Route to pass ID, and let DetailVM fetch it?
                        // Or pass the subscription object if we have it?
                        // Route uses ID.
                        // We need a way to get the subscription.
                        // Let's assume we can get it from HomeViewModel... but that's coupled.
                        // Better: DetailVM fetches by ID.
                        if let subscription = homeViewModel.subscriptions.first(where: { $0.id == id }) {
                            SubscriptionDetailView(
                                viewModel: SubscriptionDetailViewModel(
                                    subscription: subscription,
                                    subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
                                    invoiceRepository: SmartSubscriptionAppModel.shared.invoiceRepository
                                ),
                                path: $path
                            )
                        } else {
                            Text("Subscription not found")
                        }
                    case .editSubscription(let id):
                        if let subscription = homeViewModel.subscriptions.first(where: { $0.id == id }) {
                            ReviewEditSubscriptionView(
                                viewModel: ReviewEditViewModel(
                                    subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
                                    subscription: subscription
                                )
                            )
                        } else {
                            Text("Subscription not found")
                        }
                    case .analytics:
                        AnalyticsDashboardView(
                            viewModel: AnalyticsViewModel(
                                subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase
                            )
                        )
                    case .settings:
                        SettingsView(path: $path)
                    case .categoryManagement:
                        CategoryListView(
                            viewModel: CategoryListViewModel(
                                categoryUseCase: SmartSubscriptionAppModel.shared.categoryUseCase
                            )
                        )
                    }
                }
        }
        .background(Color.SmartSubscriptionSecondaryGradient)
        .applyAppearanceMode(appearanceMode)
        .onReceive(NotificationCenter.default.publisher(for: .appearanceModeDidChange)) { _ in
            appearanceMode = SettingsStore.shared.appearanceMode
        }
    }
}
