import Foundation
import SmartSubscriptionKit

public struct BillingCalculator {
    public static func calculateNextBillingDate(
        startDate: Date,
        cadence: Subscription.BillingCadence,
        referenceDate: Date = Date()
    ) -> Date {
        let calendar = Calendar.current
        
        // If start date is in the future, that is the next billing date
        if startDate > referenceDate {
            return startDate
        }
        
        var nextDate = startDate
        
        // Helper to add component
        let addComponent: (Calendar.Component, Int) -> Date? = { component, value in
            return calendar.date(byAdding: component, value: value, to: nextDate)
        }
        
        // Loop until we find a date in the future (after referenceDate)
        // Safety Break: Limit iterations to avoid infinite loops in case of weird date math, though unlikley with Calendar
        // For efficiency, we can calculate the number of periods diff for simple cadences,
        // but iteration is safer for "Same Day of Month" logic (e.g. Jan 31 -> Feb 28 -> Mar 31)
        
        // Optimization: Calculate approximate difference to jump closer
        // But for MVP and robustness, iteration is fine unless the start date is 100 years ago.
        
        switch cadence {
        case .weekly:
            // Calculate weeks between start and now
            let components = calendar.dateComponents([.weekOfYear], from: startDate, to: referenceDate)
            if let weeks = components.weekOfYear, weeks > 0 {
                // Jump to close to now
                if let jumpDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: startDate) {
                    nextDate = jumpDate
                }
            }
            while nextDate <= referenceDate {
                guard let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) else { break }
                nextDate = newDate
            }
            
        case .monthly:
            // Calculate months between start and now
            let components = calendar.dateComponents([.month], from: startDate, to: referenceDate)
            if let months = components.month, months > 0 {
                if let jumpDate = calendar.date(byAdding: .month, value: months, to: startDate) {
                    nextDate = jumpDate
                }
            }
            while nextDate <= referenceDate {
                guard let newDate = calendar.date(byAdding: .month, value: 1, to: nextDate) else { break }
                nextDate = newDate
            }
            
        case .yearly:
            // Calculate years between start and now
            let components = calendar.dateComponents([.year], from: startDate, to: referenceDate)
            if let years = components.year, years > 0 {
                 if let jumpDate = calendar.date(byAdding: .year, value: years, to: startDate) {
                    nextDate = jumpDate
                }
            }
            while nextDate <= referenceDate {
                guard let newDate = calendar.date(byAdding: .year, value: 1, to: nextDate) else { break }
                nextDate = newDate
            }
            
        case .customDays(let days):
            // Calculate roughly how many 'days' periods fit
            // This is harder to optimize with Calendar exactness, sticking to iteration or simple days math
            // Since customDays is constant, likely safe to do simple math if consistent
            // But let's stick to safe iteration with a jump if needed.
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: referenceDate).day ?? 0
            if daysBetween > days {
                let periods = daysBetween / days
                if let jumpDate = calendar.date(byAdding: .day, value: periods * days, to: startDate) {
                    nextDate = jumpDate
                }
            }
            while nextDate <= referenceDate {
                guard let newDate = calendar.date(byAdding: .day, value: days, to: nextDate) else { break }
                nextDate = newDate
            }
        }
        
        return nextDate
    }
}
