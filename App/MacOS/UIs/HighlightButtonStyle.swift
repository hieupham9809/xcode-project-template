//
//  HighlightButtonStyle.swift
//  AppTemplate
//
//  Created by Harley Pham on 1/12/24.
//

import Foundation
import SwiftUI

struct CustomHighlightButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let normalColor: LinearGradient
    let highlightOnPressColor: LinearGradient
    @Binding var isHovering: Bool

    init(
        isEnabled: Bool,
        normalColor: LinearGradient,
        highlightOnPressColor: LinearGradient,
        isHovering: Binding<Bool>
    ) {
        self.isEnabled = isEnabled
        self.normalColor = normalColor
        self.highlightOnPressColor = highlightOnPressColor
        self._isHovering = isHovering
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if isEnabled {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            configuration.isPressed
                               ? highlightOnPressColor
                               : normalColor
                        )
                        .brightness(isHovering ? -0.1 : 0)
                }
                else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray)
                }
            }
            .onContinuousHover { hover in
                switch hover {
                case .active:
                    isHovering = true
                case .ended:
                    isHovering = false
                }
            }
    }
}
