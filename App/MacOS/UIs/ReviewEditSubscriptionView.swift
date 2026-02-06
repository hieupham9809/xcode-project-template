import SwiftUI
import SmartSubscriptionKit

struct ReviewEditSubscriptionView: View {
    @StateObject var viewModel: ReviewEditViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// Optional binding to navigation path for pop-to-root after save
    var path: Binding<NavigationPath>?

    #if os(iOS)
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, provider, amount, currency, notes
    }
    #endif

    var body: some View {
        Form {
            Section(header: Text("Subscription Details")) {
                TextField("Name (e.g. Netflix)", text: $viewModel.name)
                    .onChange(of: viewModel.name) { _ in viewModel.validate() }
                    #if os(iOS)
                    .focused($focusedField, equals: .name)
                    .textContentType(.organizationName)
                    .autocorrectionDisabled()
                    #endif

                TextField("Provider", text: $viewModel.providerName)
                    #if os(iOS)
                    .focused($focusedField, equals: .provider)
                    .textContentType(.organizationName)
                    .autocorrectionDisabled()
                    #endif
            }

            if !viewModel.lineItems.isEmpty {
                Section(header: Text("Line Items")) {
                    ForEach(viewModel.lineItems, id: \.self) { item in
                        HStack {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text(item.amount.formatted)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Payment")) {
                HStack {
                    TextField("Amount", value: $viewModel.amount, format: .number)
                        .onChange(of: viewModel.amount) { _ in viewModel.validate() }
                        #if os(iOS)
                        .focused($focusedField, equals: .amount)
                        .keyboardType(.decimalPad)
                        #endif

                    TextField("Currency", text: $viewModel.currencyCode)
                        .frame(width: 60)
                        #if os(iOS)
                        .focused($focusedField, equals: .currency)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        #endif
                }

                Picker("Billing Cycle", selection: $viewModel.selectedCadence) {
                    Text("Weekly").tag(SmartSubscriptionKit.Subscription.BillingCadence.weekly)
                    Text("Monthly").tag(SmartSubscriptionKit.Subscription.BillingCadence.monthly)
                    Text("Yearly").tag(SmartSubscriptionKit.Subscription.BillingCadence.yearly)
                }

                DatePicker("Next Billing", selection: $viewModel.nextBillingDate, displayedComponents: .date)
            }

            Section(header: Text("Notes")) {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 80)
                    #if os(iOS)
                    .focused($focusedField, equals: .notes)
                    #endif
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Review Subscription")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.save()
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isSaving)
                #if os(iOS)
                .fontWeight(.semibold)
                #endif
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
            #endif
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                // If path is provided (OCR flow), pop to root
                // Otherwise just dismiss (edit flow)
                if let path = path {
                    path.wrappedValue = NavigationPath()
                } else {
                    dismiss()
                }
            }
        }
        .alert("Error Saving", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.saveError ?? "Unknown error")
        }
    }
}
