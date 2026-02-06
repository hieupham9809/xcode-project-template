import Foundation
import SmartSubscriptionKit
import SwiftUI
import Combine

@MainActor
final class AddSubscriptionViewModel: ObservableObject {
    enum AddMethod {
        case scan
        case upload
        case manual
    }

    @Published var selectedImage: URL?
    @Published var isShowingImagePicker = false
    @Published var isShowingActionSheet = false
    
    // Coordination
    @Published var navigationPath = NavigationPath()
}
