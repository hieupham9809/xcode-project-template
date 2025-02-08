//
//  AppTemplateIAPItem.swift
//
//
//  Created by Harley Pham on 25/8/24.
//

import Foundation
import SwiftUI
import StoreKit

public struct AppTemplateIAPItem {
    enum Identifier: String {
        case aCupOfCoffee = "donation.coffee.1"
        case aBeer = "donation.beer.2"
    }

    let product: SKProduct
    let title: String
    let description: String
    let icon: String
    let price: String
    let productIdentifier: String
    
    private let productsIconMap: [String: String] = [
        Identifier.aCupOfCoffee.rawValue: "☕️",
        Identifier.aBeer.rawValue: "🍺"
    ]
}

extension AppTemplateIAPItem: Identifiable {
    init(product: SKProduct) {
        self.product = product
        self.title = product.localizedTitle
        self.description = product.localizedDescription
        self.icon = productsIconMap[product.productIdentifier] ?? ""
        self.price = "\(product.price)\(product.priceLocale.currencySymbol ?? "")"
        self.productIdentifier = product.productIdentifier
    }

    public var id: String {
        productIdentifier
    }
    
    static let mockCoffee = AppTemplateIAPItem(
        product: .init(),
        title: "A cup of coffee",
        description: "Buy us a cup of coffee to support our work",
        icon: "☕️",
        price: "2.99$",
        productIdentifier: "donation.coffee.1"
    )
    
    static let mockBeer = AppTemplateIAPItem(
        product: .init(),
        title: "A beer",
        description: "Buy us a beer to support our work",
        icon: "🍺",
        price: "4.99$",
        productIdentifier: "donation.beer.1"
    )
}
