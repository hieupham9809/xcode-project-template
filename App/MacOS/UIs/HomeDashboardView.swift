import SwiftUI
import SmartSubscriptionKit

struct HomeDashboardView: View {
    @ObservedObject var viewModel: HomeDashboardViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Area
                HStack(alignment: .center) {
                    Text("Subscriptions")
                        .font(.system(size: 40, weight: .bold)) // Large Title
                        .foregroundStyle(Color.primaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Picker("", selection: $viewModel.selectedPeriod) {
                            ForEach(HomeDashboardViewModel.Period.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        
                        Button(action: {
                            path.append(NavigationRoute.addSubscription)
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                        .clipShape(Circle())
                    }
                }
                .padding(.bottom, 20)

                // Subscriptions List
                if viewModel.activeSubscriptions.isEmpty {
                    EmptyStateView {
                        path.append(NavigationRoute.addSubscription)
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.activeSubscriptions) { subscription in
                            SubscriptionCard(subscription: subscription)
                                .onTapGesture {
                                    path.append(NavigationRoute.subscriptionDetail(subscription.id))
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteSubscription(id: subscription.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(40)
        }
        .background(Color.white) // Clean white background for macOS
        .navigationTitle("") // Hide default title
        .toolbar {
             // We can keep sidebar toggle if needed, but main controls are in content
        }
        .task {
            await viewModel.loadSubscriptions()
        }
    }
}

// Removing SummaryCard from here as it's not in the main view design for iPad/macOS
// But keeping the struct if needed elsewhere or we can delete it. 
// For now, I'll comment it out or leave it unused.


struct EmptyStateView: View {
    let onAddAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.triangle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.gray)
            Text("No subscriptions yet")
                .font(.headline)
                .foregroundStyle(Color.primaryText)
            Text("Add your first subscription to start tracking your spend.")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: onAddAction) {
                Text("Add Subscription")
                    .bold()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
}
