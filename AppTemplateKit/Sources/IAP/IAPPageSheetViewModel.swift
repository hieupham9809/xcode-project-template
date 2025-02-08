//
//  AppTemplateIAPPageSheetViewModel.swift
//
//
//  Created by Harley Pham on 25/8/24.
//

import Foundation
import SwiftUI

final class AppTemplateIAPPageSheetViewModel: ObservableObject {
    private let iapManager: AppTemplateIAPManager
    @Published var iapItems: [AppTemplateIAPItem] = []
    @Published var purchaseStatus: PurchaseStatus?
    @Published var confirmPurchaseAlertItem: AppTemplateIAPItem?
    
    init(iapManager: AppTemplateIAPManager = AppTemplateIAPManager.shared) {
        self.iapManager = iapManager
        iapManager.delegate = self
    }
    
    var iapItemsCount: Int {
        iapItems.count
    }
}

extension AppTemplateIAPPageSheetViewModel {
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
    func onSelect(iapItem: AppTemplateIAPItem) {
        confirmPurchaseAlertItem = iapItem
    }
    
    @MainActor
    func onConfirmPurchase(iapItem: AppTemplateIAPItem) {
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

extension AppTemplateIAPPageSheetViewModel: AppTemplateIAPManagerDelegate {
    func didReceiveProducts(_ products: [AppTemplateIAPItem]) {
        Task { @MainActor in
            iapItems = products
        }
    }
    
    func didReceiveError(_ error: Error) {
        Task { @MainActor in
            purchaseStatus = .failed
        }
    }
    
    func didPurchaseProduct(_ product: AppTemplateIAPItem) {
        Task { @MainActor in
            purchaseStatus = .success
        }
    }
    
    func didFailPurchaseProduct(_ product: AppTemplateIAPItem, error: Error) {
        Task { @MainActor in
            purchaseStatus = .failed
        }
    }
}
