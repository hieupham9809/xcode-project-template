import Foundation

public enum BillingCalculator {
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
            calendar.date(byAdding: component, value: value, to: nextDate)
        }

        // Loop until we find a date in the future (after referenceDate)
        // Safety Break: Limit iterations to avoid infinite loops in case of weird date math, though unlikley with Calendar
        // For efficiency, we can calculate the number of periods diff for simple cadences,
        // but iteration is safer for "Same Day of Month" logic (e.g. Jan 31 -> Feb 28 -> Mar 31)

        // Optimization: Calculate approximate difference to jump closer
        // But for MVP and robustness, iteration is fine unless the start date is 100 years ago.

        switch cadence {
        case .weekly:
            // Weekly depends on the exact weekday of the start date.
            // We calculate the number of full weeks between startDate and referenceDate
            // and add that + 1 to find the next date.

            // Calculate days between start and reference
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: referenceDate).day ?? 0

            if daysBetween < 0 {
                // referenceDate is before startDate (already handled at top of function, but safety check)
                return startDate
            }

            // Current cycle index = days / 7
            let weeksPassed = daysBetween / 7

            // Check the date at the current week boundary
            if let boundaryDate = calendar.date(byAdding: .day, value: weeksPassed * 7, to: startDate) {
                // If boundary is in the future (unlikely due to math) or is today:
                if boundaryDate > referenceDate {
                    nextDate = boundaryDate
                } else {
                    // It's in the past or today, so next billing is +1 week from boundary
                    // Note: If boundaryDate == referenceDate (today), usually next billing is today?
                    // User requirement implies "next billing date". If today IS the billing date, is it Next?
                    // Usually "Next" implies "Upcoming". If I'm billed today, next is next week.
                    // But if I haven't paid yet...
                    // Let's assume strict "Future" date logic. "nextDate > referenceDate"

                    // Actually, if today is the billing date, we probably want to show today.
                    // But the top check `if startDate > referenceDate` handles "future start".
                    // If `boundaryDate == referenceDate`, it IS the billing date.

                    // Let's stick to the pattern: Find the first occurrence >= referenceDate?
                    // Or > referenceDate?
                    // The original loop condition was `while nextDate <= referenceDate`.
                    // This implies we want strictly AFTER referenceDate (since referenceDate is usually "now").
                    // If bill is due today, it's "Today", not "Next".
                    // But usually "Next Billing Date" field holds the date of the upcoming payment.
                    // If it's today, it's today.

                    // Let's use strict addition:
                    if let nextCycle = calendar.date(byAdding: .day, value: (weeksPassed + 1) * 7, to: startDate) {
                        nextDate = nextCycle
                    }
                }
            }

            // Correct logic check:
            // Start: Jan 1 (Wed). Ref: Jan 8 (Wed).
            // Days: 7. Weeks: 1.
            // Boundary: Jan 1 + 7 = Jan 8.
            // Boundary == Ref.
            // If we interpret "Next" as strictly future: we want Jan 15.
            // If we interpret "Next" as "When is the bill?", it is Jan 8.
            // Existing logic: `while nextDate <= referenceDate`. This skips today.
            // If ref is Jan 8 9:00 AM, and nextDate is Jan 8 00:00 (from math), it skips.
            // Let's stick to strict future for "Next".

            // Wait, previous logic:
            // iteration: `while nextDate <= referenceDate` -> add interval.
            // So if today is the date, it skips to next interval.

             // Re-evaluating User Request:
            // "monthly billing is likely depending on the current date time and the subscription start time's Day"
            // "yearly ... current date time ... and subscription start time's Day and Month"

            // This implies "Snap to Anchor".

        case .monthly:
            // Anchor: Start Day of Month.
            let startDay = calendar.component(.day, from: startDate)

            // Get Reference Components (Year, Month)
            let nextComponents = calendar.dateComponents([.year, .month], from: referenceDate)

            // Function to generate candidate date given year/month, clamping day
            func dateFor(year: Int, month: Int) -> Date? {
                var components = DateComponents()
                components.year = year
                components.month = month

                // Get the range of days in this month
                if let date = calendar.date(from: components),
                   let range = calendar.range(of: .day, in: .month, for: date)
                {
                    // Clamp day to max in month (e.g. 31 -> 28 in Feb)
                    components.day = min(startDay, range.count)
                    return calendar.date(from: components)
                }
                return nil
            }

            let currentYear = nextComponents.year ?? 2024
            let currentMonth = nextComponents.month ?? 1

            // Try current month
            if let candidate = dateFor(year: currentYear, month: currentMonth), candidate > referenceDate {
                nextDate = candidate
            } else {
                // Try next month (handle year rollover automatically by Calendar components if we used date(byAdding),
                // but since we are constructing components, manual rollover is needed OR use date(byAdding))

                // Better approach: Get date for 1st of current month, add 1 month, calculate clamp
                if let startOfCurrentMonth = calendar.date(from: nextComponents),
                   let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfCurrentMonth)
                {
                    let nextYear = calendar.component(.year, from: startOfNextMonth)
                    let nextMonthVal = calendar.component(.month, from: startOfNextMonth)
                    if let nextCandidate = dateFor(year: nextYear, month: nextMonthVal) {
                        nextDate = nextCandidate
                    }
                }
            }

        case .yearly:
            // Anchor: Start Day and Month.
            let startDay = calendar.component(.day, from: startDate)
            let startMonth = calendar.component(.month, from: startDate)

            let currentYear = calendar.component(.year, from: referenceDate)

            func dateForYear(_ year: Int) -> Date? {
                var components = DateComponents()
                components.year = year
                components.month = startMonth
                // Clamp day (e.g. Feb 29 -> Feb 28 in non-leap year)
                // We basically construct the month first
                components.day = 1
                if let dateOfMonth = calendar.date(from: components),
                   let range = calendar.range(of: .day, in: .month, for: dateOfMonth)
                {
                    components.day = min(startDay, range.count)
                    return calendar.date(from: components)
                }
                return nil
            }

            if let candidate = dateForYear(currentYear), candidate > referenceDate {
                nextDate = candidate
            } else {
                if let nextYearCandidate = dateForYear(currentYear + 1) {
                    nextDate = nextYearCandidate
                }
            }

        case let .customDays(days):
            // Keep existing logic or simple mod logic
            let daysBetween = calendar.dateComponents([.day], from: startDate, to: referenceDate).day ?? 0
            if daysBetween >= 0 {
                let periods = daysBetween / days
                // candidate is start + periods * days (which is <= ref)
                // next is start + (periods + 1) * days
                if let jumpDate = calendar.date(byAdding: .day, value: (periods + 1) * days, to: startDate) {
                    nextDate = jumpDate
                }
            }
        }

        return nextDate
    }
}
