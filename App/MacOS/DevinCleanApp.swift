import Combine
import AppTemplateKit
import Firebase
import SwiftUI

@main
struct AppTemplateApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    /// For managing the detail screen's navigation stack
    @State private var path = NavigationPath()
    private let appModel = AppTemplateAppModel.shared

    private let mainWindowID = "MainWindow"
    @State private var isMainWindowVisible = false

    var body: some Scene {
        Window("AppTemplate", id: mainWindowID) { // Views won't receive event when closed if we use WindowGroup
            ContentView(
                path: $path,
                viewModel: appModel.contentViewModel
            )
            .frame(minWidth: 1024, minHeight: 768)
            .onDisappear {
                isMainWindowVisible = false
            }
            .onAppear {
                isMainWindowVisible = true
            }
        }
        .defaultSize(width: 1024, height: 768)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.help) {
#if DEBUG
                Button("Debug menu item") {
                }
#endif
            }
        }

        WindowGroup { // keeping the app running when the main window is closed
            EmptyView()
                .frame(width: 0, height: 0)
        }
    }
    
    private func openMainWindowIfNeeded() {
        NSApp.activate(ignoringOtherApps: true)
        if !isMainWindowVisible {
            openWindow(id: mainWindowID)
        }
        NSApplication.shared.windows.forEach { window in
            if window.identifier?.rawValue.starts(with: mainWindowID) ?? false {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                return
            }
        }
    }

#if DEBUG
    @AppStorage("MockValueForDebugging")
    var isMockStrategyEnabled = false
#endif
}
