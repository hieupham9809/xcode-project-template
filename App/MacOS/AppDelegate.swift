//
//  AppDelegate.swift
//  AppTemplate
//
//  Created by Harley Pham on 25/8/24.
//

import AppKit
import Combine
import AppTemplateKit
import Firebase
import Foundation
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menuBarWindow: NSWindow?

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        AppEventLogger.logger = FirebaseEventLogger.shared
        AppTemplateIAPManager.shared.startObserving()
#if !APP_SANDBOX
        _ = AppUpdateManager.shared
#endif
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        AppTemplateIAPManager.shared.stopObserving()
    }
    
    @objc func toggleWindow() {
        guard let window = menuBarWindow else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else if let button = statusItem?.button {
            if let screenFrame = button.window?.screen?.frame {
                let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
                window.setFrameOrigin(
                    CGPoint(
                        x: buttonFrame.midX - window.frame.width / 2,
                        y: screenFrame.maxY - buttonFrame.height - window.frame.height - 10
                    )
                )
            }
            window.makeKeyAndOrderFront(nil)
            window.level = .statusBar
            window.orderFrontRegardless()
        }
    }
}

class FocusTrackingWindow: NSWindow {
    override func resignMain() {
        super.resignMain()
        // Hide the window when it loses focus
        self.orderOut(nil)
    }
    
    override var canBecomeKey: Bool { true }
    
    override var canBecomeMain: Bool { true }
}
