//
//  View+onNavigateBack.swift
//  AppTemplatKit
//
//  Created by Harley Pham on 16/1/25.
//

import Foundation
import SwiftUI

struct PathObserverViewModifier: ViewModifier {
    @State private var currentDepth: Int = 0
    @Binding var path: NavigationPath
    @State private var screenDepth: Int = 0
    let onNavigatingBack: (() -> Void)?

    init(path: Binding<NavigationPath>, onNavigatingBack: (() -> Void)?) {
        self._path = path
        self.onNavigatingBack = onNavigatingBack
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                screenDepth = path.count
            }
            .onChange(of: path) { newPath in
                if screenDepth == newPath.count && newPath.count < currentDepth {
                    onNavigatingBack?()
                }
                currentDepth = newPath.count
            }
    }
}

extension View {
    public func onNavigateBack(of path: Binding<NavigationPath>, handler: (() -> Void)?) -> some View {
        modifier(PathObserverViewModifier(path: path, onNavigatingBack: handler))
    }
}
