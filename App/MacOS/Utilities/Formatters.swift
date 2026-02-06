import Foundation
import SmartSubscriptionKit

struct Formatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0 // Allow $20 instead of $20.00 if exact
        return formatter
    }()
    
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension Money {
    var formatted: String {
        let formatter = Formatters.currency
        formatter.currencyCode = self.currencyCode
        return formatter.string(from: self.amount as NSDecimalNumber) ?? "\(self.currencyCode) \(self.amount)"
    }
}
