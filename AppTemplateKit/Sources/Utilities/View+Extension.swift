//
//  View+Extension.swift
//
//
//  Created by Harley Pham on 08/06/2024.
//

import Foundation
import SwiftUI

extension View {
    public func size(_ handler: @escaping (CGSize) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        handler(proxy.size)
                    }
                    .onChange(of: proxy.size) { _ in
                        handler(proxy.size)
                    }
            }
        }
    }
    
    public func frame(_ size: CGSize) -> some View {
        frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    public func applyIf<ViewOnTrue: View, ViewOnFalse: View>(
        _ condition: Bool,
        transformOnTrue: (Self) -> ViewOnTrue,
        transformOnFalse: (Self) -> ViewOnFalse
    ) -> some View {
        if condition {
            transformOnTrue(self)
        } else {
            transformOnFalse(self)
        }
    }

    public func customizeBackButton(action: (() -> Void)? = nil) -> some View {
        navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    action?()
                } label: {
                    HStack(spacing: 8) {
                        Image(.backIc)
                            .resizable()
                            .frame(.init(width: 40, height: 40))
                        
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.primaryText)
                    }
                }
                // unbordered and transparent button
                .buttonStyle(PlainButtonStyle())
            }
        }
        .toolbarBackground(Color.clear, for: .windowToolbar)
    }

    public func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppear(action: action))
    }
}

private struct FirstAppear: ViewModifier {
    let action: () -> Void

    // Use this to only fire your block one time
    @State private var isFirstAppear = true

    func body(content: Content) -> some View {

        content.onAppear {
            if isFirstAppear {
                print("First")
                isFirstAppear = false
                action()
            }

        }
    }
}
