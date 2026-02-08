import Foundation
import SmartSubscriptionKit
import SwiftUI

@MainActor
final class CategoryEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var colorHex: String = "#000000"
    @Published var iconName: String = "circle.fill"
    @Published var isSaving = false
    @Published var error: String?
    @Published var shouldDismiss = false

    private let categoryUseCase: CategoryUseCase
    private let existingCategory: SubscriptionCategory?

    var isNew: Bool { existingCategory == nil }

    init(categoryUseCase: CategoryUseCase, category: SubscriptionCategory? = nil) {
        self.categoryUseCase = categoryUseCase
        self.existingCategory = category
        if let category {
            name = category.name
            colorHex = category.colorHex
            iconName = category.iconName
        } else {
            // Defaults
            colorHex = "#FF5733"
            iconName = "tag"
        }
    }

    func save() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "Name cannot be empty"
            return
        }

        isSaving = true
        do {
            let category = SubscriptionCategory(
                id: existingCategory?.id ?? SubscriptionCategory.ID(),
                name: name,
                colorHex: colorHex,
                iconName: iconName,
                sortOrder: existingCategory?.sortOrder ?? 0,
                createdAt: existingCategory?.createdAt ?? Date(),
                updatedAt: Date()
            )

            if isNew {
                try await categoryUseCase.addCategory(category)
            } else {
                try await categoryUseCase.updateCategory(category)
            }
            shouldDismiss = true
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
