//
//  ContentView.swift
//  AppTemplate
//
//  Created by Harley Pham on 18/05/2024.
//

import AppTemplateKit
import Foundation
import os
import SwiftUI
import AppKit

private let logger = Logger(subsystem: "AppTemplate", category: "ContentView")

public struct ContentView: View {
    @Binding var path: NavigationPath
    private var viewModel: ContentViewModel

    init(
        path: Binding<NavigationPath>,
        viewModel: ContentViewModel
    ) {
        self._path = path
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack(path: $path) {
            Text("ContentView")
//            .navigationDestination(for: Panel.self) { panel in
//
//            }
        }
        .background(Color.AppTemplateSecondaryGradient)
    }
}
