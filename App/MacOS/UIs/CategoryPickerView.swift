import SmartSubscriptionKit
import SwiftUI

struct CategoryPickerView: View {
    @Binding var selection: SubscriptionCategory.ID?
    @StateObject private var viewModel = CategoryListViewModel(categoryUseCase: SmartSubscriptionAppModel.shared.categoryUseCase)

    var body: some View {
        Picker("Category", selection: $selection) {
            Text("None").tag(SubscriptionCategory.ID?.none)
            Divider()
            ForEach(viewModel.categories) { category in
                HStack {
                    Image(systemName: category.iconName)
                    Text(category.name)
                }
                .tag(category.id)
            }
        }
    }
}
