import SmartSubscriptionKit
import SwiftUI
#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

struct SubscriptionDetailView: View {
    @StateObject var viewModel: SubscriptionDetailViewModel
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    #if os(iOS)
        @State private var selectedInvoiceImage: InvoiceImageWrapper?
    #endif

    var body: some View {
        ScrollView {
            // ... (rest of body content is unchanged by this specific replacement block targeting state/modifiers)
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.SmartSubscriptionMainGradient)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(viewModel.subscription.name.prefix(1)).uppercased())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        )

                    VStack(spacing: 8) {
                        Text(viewModel.subscription.name)
                            .font(.title)
                            .bold()

                        Text(viewModel.subscriptionAmountFormatted)
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.primaryText)

                        Text("/ \(viewModel.subscription.cadence.description.lowercased())")
                            .foregroundStyle(Color.secondaryText)
                    }
                }
                .padding(.top, 40)

                // Info Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    InfoTile(title: "Status", value: viewModel.subscription.status.rawValue.capitalized)
                    InfoTile(title: "Next Billing", value: viewModel.subscription.nextBillingDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")
                    InfoTile(title: "Provider", value: viewModel.subscription.providerName ?? "-")
                    InfoTile(title: "Started", value: viewModel.subscription.startDate.formatted(date: .abbreviated, time: .omitted))
                }
                .padding(.horizontal)

                // Line Items (from latest invoice)
                if let latestInvoice = viewModel.invoices.first, !latestInvoice.lineItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Items")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(latestInvoice.lineItems, id: \.self) { item in
                                HStack {
                                    Text(item.title)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primaryText)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Text(item.amount.amount.formattedAsCurrency(code: viewModel.subscription.amount.currencyCode))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondaryText)
                                }
                                .padding()

                                if item != latestInvoice.lineItems.last {
                                    Divider().padding(.leading)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }

                // Invoice History (iOS)
                #if os(iOS)
                    invoiceHistorySection
                #endif

                // Notes
                if let notes = viewModel.subscription.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .foregroundStyle(Color.secondaryText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        #if os(macOS)
                            .background(Color(NSColor.controlBackgroundColor))
                        #else
                            .background(Color(uiColor: .secondarySystemBackground))
                        #endif
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Actions
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteSubscription()
                    }
                } label: {
                    Text("Delete Subscription")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                .padding()
            }
        }

        #if os(macOS)
        .background(Color.white.ignoresSafeArea())
        #else
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        #endif
        .navigationTitle(viewModel.subscription.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        path.append(NavigationRoute.editSubscription(viewModel.subscription.id))
                    }
                }
            }
            .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    if !path.isEmpty {
                        path.removeLast()
                    }
                }
            }
        #if os(iOS)
            .fullScreenCover(item: $selectedInvoiceImage) { wrapper in
                ImageViewer(imageURL: wrapper.url)
            }
        #endif
            .task {
                await viewModel.loadInvoices()
            }
    }

    #if os(iOS)
        struct InvoiceImageWrapper: Identifiable {
            let id = UUID()
            let url: URL
        }
    #endif

    #if os(iOS)
        @ViewBuilder
        private var invoiceHistorySection: some View {
            let invoicesWithImages = viewModel.invoices.filter { $0.sourceImageURL != nil }
            if !invoicesWithImages.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Invoice History")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(invoicesWithImages, id: \.id) { invoice in
                                if let url = invoice.sourceImageURL,
                                   let data = try? Data(contentsOf: url),
                                   let uiImage = UIImage(data: data)
                                {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 100)
                                        .cornerRadius(8)
                                        .clipped()
                                        .onTapGesture {
                                            selectedInvoiceImage = InvoiceImageWrapper(url: url)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    #endif
}

struct InfoTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
