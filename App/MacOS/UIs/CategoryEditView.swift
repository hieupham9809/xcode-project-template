import SmartSubscriptionKit
import SwiftUI

struct CategoryEditView: View {
    @StateObject var viewModel: CategoryEditViewModel
    @Environment(\.dismiss) private var dismiss

    let commonColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#DDA0DD", "#F7DC6F", "#82E0AA", "#BDC3C7",
        "#FF5733", "#C70039", "#900C3F", "#581845"
    ]
    
    let commonIcons = [
        "tv", "laptopcomputer", "cloud", "music.note",
        "gamecontroller", "newspaper", "dollarsign.circle", "ellipsis.circle",
        "cart", "house", "car", "book"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Name", text: $viewModel.name)
                    
                    VStack(alignment: .leading) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                            ForEach(commonIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(viewModel.iconName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        viewModel.iconName = icon
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading) {
                        Text("Color")
                             .font(.caption)
                             .foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 30))]) {
                            ForEach(commonColors, id: \.self) { hex in
                                if let hexInt = Int(hex.dropFirst(), radix: 16) {
                                    Circle()
                                        .fill(Color(hex: hexInt))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: viewModel.colorHex == hex ? 2 : 0)
                                        )
                                        .onTapGesture {
                                            viewModel.colorHex = hex
                                        }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if let error = viewModel.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(viewModel.isNew ? "New Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.save() }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.shouldDismiss) { should in
                if should { dismiss() }
            }
        }
    }
}
