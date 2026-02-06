//
//  SmartSubscriptionIAPPageSheetViewModel.swift
//
//
//  Created by Harley Pham on 25/8/24.
//

import Foundation
import SwiftUI

final class SmartSubscriptionIAPPageSheetViewModel: ObservableObject {
    private let iapManager: SmartSubscriptionIAPManager
    @Published var iapItems: [SmartSubscriptionIAPItem] = []
    @Published var purchaseStatus: PurchaseStatus?
    @Published var confirmPurchaseAlertItem: SmartSubscriptionIAPItem?
    
    init(iapManager: SmartSubscriptionIAPManager = SmartSubscriptionIAPManager.shared) {
        self.iapManager = iapManager
        iapManager.delegate = self
    }
    
    var iapItemsCount: Int {
        iapItems.count
    }
}

extension SmartSubscriptionIAPPageSheetViewModel {
    enum PurchaseStatus {
        case loading
        case success
        case failed
    }
    
    @MainActor
    func onAppear() {
        iapManager.fetchProducts()
    }
    
    @MainActor
    func onSelect(iapItem: SmartSubscriptionIAPItem) {
        confirmPurchaseAlertItem = iapItem
    }
    
    @MainActor
    func onConfirmPurchase(iapItem: SmartSubscriptionIAPItem) {
        purchaseStatus = .loading
        iapManager.purchaseProduct(iapItem)
    }
    
    @MainActor
    func onTryAgain() {
        purchaseStatus = nil
    }
    
    @MainActor
    func onCompletePurchase() {
        purchaseStatus = nil
    }
}

extension SmartSubscriptionIAPPageSheetViewModel: SmartSubscriptionIAPManagerDelegate {
    func didReceiveProducts(_ products: [SmartSubscriptionIAPItem]) {
        Task { @MainActor in
            iapItems = products
        }
    }
    
    func didReceiveError(_ error: Error) {
        Task { @MainActor in
            purchaseStatus = .failed
        }
    }
    
    func didPurchaseProduct(_ product: SmartSubscriptionIAPItem) {
        Task { @MainActor in
            purchaseStatus = .success
        }
    }
    
    func didFailPurchaseProduct(_ product: SmartSubscriptionIAPItem, error: Error) {
        Task { @MainActor in
            purchaseStatus = .failed
        }
    }
}
