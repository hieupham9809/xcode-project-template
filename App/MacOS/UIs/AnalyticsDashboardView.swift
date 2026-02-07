import Charts
import SwiftUI
#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

struct AnalyticsDashboardView: View {
    @StateObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Total Monthly Spend")
                        .font(.headline)
                        .foregroundStyle(Color.secondaryText)

                    Text(viewModel.totalSpend.formattedAsCurrency(code: viewModel.displayCurrency))
                    #if os(iOS)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    #else
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    #endif
                        .foregroundStyle(Color.primaryText)
                }
                .padding(.top, 24)

                // Spend by Category Chart
                VStack(alignment: .leading, spacing: 16) {
                    Text("Spend by Provider")
                        .font(.title3)
                        .bold()

                    Chart(viewModel.spendByCategory, id: \.0) { item in
                        BarMark(
                            x: .value("Amount", item.1),
                            y: .value("Provider", item.0)
                        )
                        .foregroundStyle(Color.SmartSubscriptionMainGradient)
                        .annotation(position: .trailing) {
                            Text(item.1.formattedAsCurrency(code: viewModel.displayCurrency))
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                    #if os(iOS)
                    .frame(height: 220)
                    #else
                    .frame(height: 300)
                    #endif
                }
                .padding()
                #if os(macOS)
                    .background(Color(nsColor: .windowBackgroundColor))
                #else
                    .background(Color(uiColor: .secondarySystemBackground))
                #endif
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                    .padding(.horizontal)

                // Trend
                VStack(alignment: .leading, spacing: 16) {
                    Text("Projected Spend (6 Months)")
                        .font(.title3)
                        .bold()

                    Chart(viewModel.monthlyTrend, id: \.0) { item in
                        LineMark(
                            x: .value("Month", item.0, unit: .month),
                            y: .value("Amount", item.1)
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbol(Circle())
                    }
                    #if os(iOS)
                    .frame(height: 160)
                    #else
                    .frame(height: 200)
                    #endif
                }
                .padding()
                #if os(macOS)
                    .background(Color(nsColor: .windowBackgroundColor))
                #else
                    .background(Color(uiColor: .secondarySystemBackground))
                #endif
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8)
                    .padding(.horizontal)
            }
        }
        #if os(macOS)
        .background(Color.white)
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
        .navigationTitle("Analytics")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
            .task {
                await viewModel.loadAnalytics()
            }
    }
}
