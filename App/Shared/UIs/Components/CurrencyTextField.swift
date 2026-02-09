import SwiftUI
import Combine

struct CurrencyTextField: View {
    @Binding var value: Decimal
    var currencyCode: String
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    private var formatter: NumberFormatter {
        let formatter = Formatters.currencyFormatter(for: currencyCode)
        formatter.numberStyle = .decimal
        return formatter
    }
    
    var body: some View {
        TextField("Amount", text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: isFocused) { focused in
                if focused {
                    // When focused, we might want to show the raw number or keep it formatted.
                    // Keeping it formatted is usually better for "Currency" style apps.
                    // But if it's 0, maybe clear it?
                    if value == 0 {
                        text = ""
                    } else {
                        text = format(value)
                    }
                } else {
                    // When focus is lost, re-format strictly
                    text = format(value)
                }
            }
            .onChange(of: value) { newValue in
                // If value changes externally (e.g. loaded), update text if not focused or if vastly different
                if !isFocused {
                    text = format(newValue)
                }
            }
            .onChange(of: text) { newValue in
                // logic to parse string back to decimal
                // Filter out non-numeric characters except decimal separator
                let filtered = newValue.filter { "0123456789.,".contains($0) }
                if filtered != newValue {
                    text = filtered
                    return
                }
                
                if let decimal = parse(filtered) {
                    value = decimal
                }
            }
            .onAppear {
                text = format(value)
            }
    }
    
    private func format(_ number: Decimal) -> String {
        return formatter.string(from: number as NSDecimalNumber) ?? ""
    }
    
    private func parse(_ string: String) -> Decimal? {
        // This is tricky because of different locales.
        // We'll try to stick to the formatter's logic or a standard strategy.
        // If the user types "1,000", the formatter handles it.
        return formatter.number(from: string)?.decimalValue
    }
}
