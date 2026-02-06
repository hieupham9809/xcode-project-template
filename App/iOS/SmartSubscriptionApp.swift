import SwiftUI
import SmartSubscriptionKit

@main
struct SmartSubscriptionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private let appModel = SmartSubscriptionAppModel.shared
    @State private var path = NavigationPath()
    
    var body: some Scene {
        WindowGroup {
            ContentView(path: $path, viewModel: appModel.contentViewModel)
        }
    }
}
