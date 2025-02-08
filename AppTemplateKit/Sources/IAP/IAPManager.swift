//
//  AppTemplateIAPManager.swift
//
//
//  Created by Harley Pham on 25/8/24.
//

import Foundation
import StoreKit

public protocol AppTemplateIAPManagerDelegate: AnyObject {
    func didReceiveProducts(_ products: [AppTemplateIAPItem])
    func didReceiveError(_ error: Error)
    func didPurchaseProduct(_ product: AppTemplateIAPItem)
    func didFailPurchaseProduct(_ product: AppTemplateIAPItem, error: Error)
}

private let scanLogger = Log.initialize(category: .iap)
public class AppTemplateIAPManager: NSObject {
    public static let shared = AppTemplateIAPManager()
    public weak var delegate: AppTemplateIAPManagerDelegate?
    var productItems: [AppTemplateIAPItem] = []

    private var isFetchingProducts = false

    public func fetchProducts() {
        guard !isFetchingProducts else {
            logger.info("Already fetching products")
            return
        }
        let productIdentifiers = Set<String>(
            [AppTemplateIAPItem.Identifier.aCupOfCoffee, .aBeer]
            .map { $0.rawValue }
        )
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
        isFetchingProducts = true
        logger.info("Fetching products: \(productIdentifiers)")
    }
}

extension AppTemplateIAPManager: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let productItems = response.products.map { product -> AppTemplateIAPItem in
            return AppTemplateIAPItem(product: product)
        }
        self.productItems = productItems
        logger.info("Received products: \(response.products)")
        delegate?.didReceiveProducts(productItems)
        isFetchingProducts = false
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        logger.error("Failed to fetch products: \(error)")
        delegate?.didReceiveError(error)
        isFetchingProducts = false
    }
}

extension AppTemplateIAPManager: SKPaymentTransactionObserver {
    public func purchaseProduct(_ product: AppTemplateIAPItem) {
        guard SKPaymentQueue.canMakePayments() else {
            logger.error("User cannot make payments")
            delegate?.didFailPurchaseProduct(
                product,
                error: NSError(domain: "canMakePayments false", code: 0, userInfo: nil)
            )
            return
        }
        let payment = SKPayment(product: product.product)
        SKPaymentQueue.default().add(payment)
        logger.info("Purchasing product: \(product.title)")
    }
    
    public func startObserving() {
        SKPaymentQueue.default().add(self)
    }
    
    public func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    
    public func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        transactions.forEach { transaction in
            guard let product = productItems.first(where: { $0.productIdentifier == transaction.payment.productIdentifier }) else {
                logger.error("Product not found: \(transaction.payment.productIdentifier)")
                queue.finishTransaction(transaction)
                return
            }
            switch transaction.transactionState {
            case .purchased:
                logger.info("Purchased product: \(transaction.payment.productIdentifier)")
                delegate?.didPurchaseProduct(product)
                queue.finishTransaction(transaction)
            case .failed:
                logger.error("Failed to purchase product: \(transaction.payment.productIdentifier)")
                delegate?.didFailPurchaseProduct(
                    product,
                    error: transaction.error ?? NSError(domain: "Unknown error", code: 0, userInfo: nil)
                )
                queue.finishTransaction(transaction)
            case .restored:
                logger.info("Restored product: \(transaction.payment.productIdentifier)")
                delegate?.didPurchaseProduct(
                    productItems.first { $0.productIdentifier == transaction.payment.productIdentifier }!
                )
                queue.finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
