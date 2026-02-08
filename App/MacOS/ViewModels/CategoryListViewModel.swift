import Foundation
import SmartSubscriptionKit
import Combine

@MainActor
final class CategoryListViewModel: ObservableObject {
    @Published var categories: [SubscriptionCategory] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let categoryUseCase: CategoryUseCase

    init(categoryUseCase: CategoryUseCase) {
        self.categoryUseCase = categoryUseCase
        Task { await loadCategories() }
    }

    func loadCategories() async {
        isLoading = true
        do {
            // Also seed default categories if needed
            // Ideally seeding should happen at app launch, but we can check here too or assume AppModel handles it.
            // Since CategoryRepository has seedDefaultCategoriesIfNeeded, we might want to call it.
            // But let's assume UseCase or Repository handles it or we call it here.
            // The plan didn't expose seedDefaultCategoriesIfNeeded in UseCase interface.
            // So we'll trust it's populated or user adds them.
            // Wait, the plan's repository included `seedDefaultCategoriesIfNeeded` but UseCase didn't.
            // I should update UseCase if I want to use it.
            // For now, let's just fetch.
            categories = try await categoryUseCase.getAllCategories()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func deleteCategory(_ category: SubscriptionCategory) async {
        do {
            try await categoryUseCase.deleteCategory(id: category.id)
            await loadCategories()
        } catch {
            self.error = error
        }
    }
}
