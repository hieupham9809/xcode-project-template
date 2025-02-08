//
//  TransparentHostingController.swift
//  AppTemplate
//
//  Created by Harley Pham on 8/12/24.
//

import AppKit
import Foundation
import SwiftUI

final class TransparentHostingController<Content>: NSHostingController<Content> where Content: View {
    override func loadView() {
        super.loadView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard let window = view.window else { return }

        // Make the window fully transparent
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false // Optional: Remove the shadow

        // Remove the blur effect
        if let visualEffectView = window.contentView?.superview?.subviews.first(where: { $0 is NSVisualEffectView }) as? NSVisualEffectView {
            visualEffectView.material = .windowBackground
            visualEffectView.state = .inactive
        }
    }
}
