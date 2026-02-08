import SmartSubscriptionKit
import SwiftUI

struct CategoryListView: View {
    @StateObject var viewModel: CategoryListViewModel
    @State private var showingAddSheet = false
    @State private var categoryToEdit: SubscriptionCategory?

    var body: some View {
        if viewModel.isLoading && viewModel.categories.isEmpty {
            ProgressView()
        } else {
            List {
                ForEach(viewModel.categories) { category in
                    Button {
                        categoryToEdit = category
                    } label: {
                        HStack {
                            if let hex = Int(category.colorHex.dropFirst(), radix: 16) {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(Color(hex: hex))
                            } else {
                                Image(systemName: category.iconName)
                            }
                            Text(category.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteCategory(category) }
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                CategoryEditView(viewModel: CategoryEditViewModel(categoryUseCase: SmartSubscriptionAppModel.shared.categoryUseCase))
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryEditView(viewModel: CategoryEditViewModel(categoryUseCase: SmartSubscriptionAppModel.shared.categoryUseCase, category: category))
            }
        }
    }
}
