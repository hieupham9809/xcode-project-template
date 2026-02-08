import SwiftUI
import SmartSubscriptionKit

struct HomeDashboardView: View {
    @ObservedObject var viewModel: HomeDashboardViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(uiColor: .secondarySystemBackground)
                .ignoresSafeArea()
            // Header Gradient
            Color.brandHeaderGradient
                .background {
                    Image(.backgroundHome)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.25)
                }
                .frame(height: 300)
                .clipped()
                .ignoresSafeArea()
                
                
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Subscriptions")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            path.append(NavigationRoute.addSubscription)
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Custom Segmented Control
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        ForEach(HomeDashboardViewModel.Period.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark) // Force dark mode for contrast on blue
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Approximate safe area
                .padding(.bottom, 16) // Reduced to allow SummaryCard to overlap into gradient
                
                // Content Layer
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Summary Card (Overlapping with header via reduced header bottom padding)
                        SummaryCard(
                            totalSpend: viewModel.totalSpend,
                            selectedPeriod: $viewModel.selectedPeriod
                        )

                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // "All" Chip
                                CategoryChip(
                                    title: "All",
                                    isSelected: viewModel.selectedCategory == nil,
                                    color: Color.accentColor,
                                    iconName: nil
                                ) {
                                    viewModel.selectedCategory = nil
                                }

                                // Category Chips
                                ForEach(viewModel.categories) { category in
                                    CategoryChip(
                                        title: category.name,
                                        isSelected: viewModel.selectedCategory == category.id,
                                        color: Color(hexString: category.colorHex),
                                        iconName: category.iconName
                                    ) {
                                        viewModel.selectedCategory = viewModel.selectedCategory == category.id ? nil : category.id
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Active Subscriptions List
                        VStack(spacing: 16) {
                            if viewModel.isLoading && viewModel.activeSubscriptions.isEmpty {
                                ForEach(0..<3, id: \.self) { _ in
                                    SubscriptionCardSkeleton()
                                }
                            } else if viewModel.activeSubscriptions.isEmpty {
                                EmptyStateView {
                                    path.append(NavigationRoute.addSubscription)
                                }
                            } else {
                                ForEach(viewModel.activeSubscriptions) { subscription in
                                    Button {
                                        HapticManager.lightImpact()
                                        path.append(NavigationRoute.subscriptionDetail(subscription.id))
                                    } label: {
                                        SubscriptionCard(subscription: subscription)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            HapticManager.warning()
                                            Task {
                                                await viewModel.deleteSubscription(id: subscription.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                }
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.activeSubscriptions.map(\.id))
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 100) // Bottom padding
                    }
                }
                .refreshable {
                    await viewModel.loadSubscriptions()
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button {
                        HapticManager.lightImpact()
                        path.append(NavigationRoute.analytics)
                    } label: {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }

                    Spacer()

                    Button {
                        HapticManager.lightImpact()
                        path.append(NavigationRoute.settings)
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
        }
        .task {
            await viewModel.loadSubscriptions()
        }
    }
}

struct SummaryCard: View {
    let totalSpend: String
    @Binding var selectedPeriod: HomeDashboardViewModel.Period

    var body: some View {
        VStack(spacing: 8) {
            Text("Total \(totalSpend)/month") // Design says "Total $XX.XX/month"
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

struct EmptyStateView: View {
    let onAddAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.triangle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.gray)
            Text("No subscriptions yet")
                .font(.headline)
                .foregroundStyle(Color.primary)
            Text("Add your first subscription to start tracking your spend.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
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
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Loading Skeleton

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + phase * (geometry.size.width * 1.6))
                    .clipped()
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

struct SubscriptionCardSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 14)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 20)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .modifier(ShimmerModifier())
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let iconName: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? color : .primary)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
