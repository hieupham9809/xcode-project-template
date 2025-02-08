//
//  File.swift
//  
//
//  Created by Phong Tran 2 on 8/8/24.
//

import SwiftUI

struct PulseEffect<S: Shape>: ViewModifier {
    let shape: S
    let color: Color
    let lineWidth: CGFloat
    let fromScale: CGFloat
    let toScale: CGFloat
    let fromOpacity: CGFloat
    let toOpacity: CGFloat
    @State private var isOn = false

    var animation: Animation {
        Animation
            .easeIn(duration: 1.3)
            .repeatForever(autoreverses: false)
    }

    func body(content: Content) -> some View {
        content
            .background(
                shape
                    .stroke(Color.AppTemplateMainGradient, lineWidth: lineWidth)
                    .scaleEffect(isOn ? toScale : fromScale)
                    .opacity(isOn ? fromOpacity : toOpacity)
            )
            .onAppear {
                withAnimation(animation) {
                    isOn = true
                }
            }
    }
}

public extension View {
    func pulse<S: Shape>(
        _ shape: S,
        color: Color,
        lineWidth: CGFloat = 2,
        fromScale: CGFloat = 1,
        toScale: CGFloat = 1.3,
        fromOpacity: CGFloat = 0,
        toOpacity: CGFloat = 0.7
    ) -> some View  {
        self.modifier(
            PulseEffect(
                shape: shape,
                color: color,
                lineWidth: lineWidth,
                fromScale: fromScale,
                toScale: toScale,
                fromOpacity: fromOpacity,
                toOpacity: toOpacity
            )
        )
    }
}
