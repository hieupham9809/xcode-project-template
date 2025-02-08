//
//  HoveringButtonStyle.swift
//  AppTemplate
//
//  Created by Harley Pham on 13/1/25.
//

import Foundation
import SwiftUI

public struct HoveringButtonStyle: ButtonStyle {
    @State var isHovering: Bool = false
    let backgroundColor: Color
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            .contentShape(Rectangle())
            .font(.system(size: 8, weight: .bold))
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .brightness(isHovering ? -0.1 : 0)
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
