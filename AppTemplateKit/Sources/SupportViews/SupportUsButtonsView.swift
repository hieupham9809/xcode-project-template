//
//  SupportUsButtonsView.swift
//
//
//  Created by Harley Pham on 3/8/24.
//

import Foundation
import SwiftUI

public struct SupportUsButtonsView: View {
    @Environment(\.openURL) private var openURL
    let paypalURLString = Support.Button.paypalURLString
    let buymeacoffeeURLString = Support.Button.buymeacoffeeURLString

    public init() {}

    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("Support us:")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .padding(6)
            
            SupportPaypalButton()
            
            SupportBuymeacoffeeButton()
        }
    }
}

public struct SupportPaypalButton: View {
    @Environment(\.openURL) private var openURL
    let paypalURLString = Support.Button.paypalURLString
    
    public init() {}

    public var body: some View {
        Button(action: {
            if let url = URL(string: paypalURLString) {
                openURL(url)
            }
        }) {
            Image(.paypalIc)
                .resizable()
                .frame(.init(width: 32, height: 32))
        }
        .buttonStyle(SupportButtonStyle(backgroundColor: Color(hex: 0xD0F5FF)))
    }
}

public struct SupportBuymeacoffeeButton: View {
    @Environment(\.openURL) private var openURL
    let buymeacoffeeURLString = Support.Button.buymeacoffeeURLString
    
    public init() {}

    public var body: some View {
        Button(action: {
            if let url = URL(string: buymeacoffeeURLString) {
                openURL(url)
            }
        }) {
            Image(.buymeIc)
                .frame(.init(width: 32, height: 32))
                .aspectRatio(contentMode: .fill)
        }
        .buttonStyle(SupportButtonStyle(backgroundColor: Color(hex: 0xFFDD00)))
    }
}

struct SupportButtonStyle: ButtonStyle {
    let backgroundColor: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .frame(.init(width: 64, height: 64))
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? .white.opacity(0.2) : .clear)
            )
    }
}

#Preview {
    SupportUsButtonsView()
}
