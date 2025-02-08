//
//  View+UIKitLifeCycles.swift
//
//
//  Created by Harley Pham on 24/7/24.
//

import Foundation
import SwiftUI
import Cocoa

extension View {
    public func onWillAppear(_ perform: @escaping () -> Void) -> some View {
        modifier(WillAppearModifier(callback: perform))
    }
}

struct WillAppearModifier: ViewModifier {
    let callback: () -> Void

    func body(content: Content) -> some View {
        content.background(NSViewLifeCycleHandler(onWillAppear: callback))
    }
}

struct NSViewLifeCycleHandler: NSViewControllerRepresentable {
    typealias NSViewControllerType = NSViewController

    var onWillAppear: () -> Void = { }

    func makeNSViewController(context: NSViewControllerRepresentableContext<Self>) -> NSViewControllerType {
        context.coordinator
    }

    func updateNSViewController(
        _: NSViewControllerType,
        context _: NSViewControllerRepresentableContext<Self>
    ) { }

    func makeCoordinator() -> Self.Coordinator {
        Coordinator(onWillAppear: onWillAppear)
    }

    class Coordinator: NSViewControllerType {
        let onWillAppear: (() -> Void)?

        init(onWillAppear: (() -> Void)? = nil) {
            self.onWillAppear = onWillAppear
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear() {
            super.viewWillAppear()
            DispatchQueue.main.async {
                self.onWillAppear?()
            }
        }
    }
}
