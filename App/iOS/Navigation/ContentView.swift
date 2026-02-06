import SwiftUI
import SmartSubscriptionKit

struct ContentView: View {
    @Binding var path: NavigationPath
    private var viewModel: ContentViewModel
    @StateObject private var homeViewModel: HomeDashboardViewModel

    init(
        path: Binding<NavigationPath>,
        viewModel: ContentViewModel
    ) {
        self._path = path
        self.viewModel = viewModel
        self._homeViewModel = StateObject(wrappedValue: HomeDashboardViewModel(
            subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase
        ))
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeDashboardView(viewModel: homeViewModel, path: $path)
                .navigationDestination(for: NavigationRoute.self) { route in
                    switch route {
                    case .addSubscription:
                        AddSubscriptionView(
                            path: $path,
                            invoiceOCRUseCase: SmartSubscriptionAppModel.shared.invoiceOCRUseCase,
                            subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase
                        )
                    case .ocrProcessing(let url):
                        OCRProcessingView(
                            imageURL: url,
                            viewModel: OCRProcessingViewModel(
                                invoiceOCRUseCase: SmartSubscriptionAppModel.shared.invoiceOCRUseCase
                            ),
                            onCompletion: { invoice in
                                path.append(NavigationRoute.reviewSubscription(invoice))
                            }
                        )
                    case .reviewSubscription(let invoice):
                        ReviewEditSubscriptionView(
                            viewModel: ReviewEditViewModel(
                                subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
                                invoiceRepository: SmartSubscriptionAppModel.shared.invoiceRepository,
                                invoice: invoice
                            ),
                            path: $path
                        )
                    case .subscriptionDetail(let id):
                         if let subscription = homeViewModel.subscriptions.first(where: { $0.id == id }) {
                            SubscriptionDetailView(
                                viewModel: SubscriptionDetailViewModel(
                                    subscription: subscription,
                                    subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
                                    invoiceRepository: SmartSubscriptionAppModel.shared.invoiceRepository
                                ),
                                path: $path
                            )
                        } else {
                            Text("Subscription not found")
                        }
                    case .editSubscription(let id):
                        if let subscription = homeViewModel.subscriptions.first(where: { $0.id == id }) {
                            ReviewEditSubscriptionView(
                                viewModel: ReviewEditViewModel(
                                    subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase,
                                    subscription: subscription
                                )
                            )
                        } else {
                            Text("Subscription not found")
                        }
                    case .analytics:
                        AnalyticsDashboardView(
                            viewModel: AnalyticsViewModel(
                                subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase
                            )
                        )
                    case .settings:
                        SettingsView(
                            viewModel: SettingsViewModel(
                                settingsStore: SmartSubscriptionAppModel.shared.settingsStore,
                                subscriptionUseCase: SmartSubscriptionAppModel.shared.subscriptionUseCase
                            ),
                            path: $path
                        )
                    }
                }
        }
    }
}
