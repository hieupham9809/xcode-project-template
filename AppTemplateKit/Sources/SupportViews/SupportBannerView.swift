//
//  SupportBannerView.swift
//
//
//  Created by Harley Pham on 3/8/24.
//

import Foundation
import SwiftUI

public enum Support {
    public enum Banner {
        public static let url = "https://swiftclean-be67e.web.app/support.html"
    }
    
    public enum Button {
        public static let paypalURLString = "https://paypal.me/flyingharley"
        public static let buymeacoffeeURLString = "https://buymeacoffee.com/flyingharley"
    }
}

public struct SupportBannerView: View {
    var actionHandler: ((_ isAccepted: Bool) -> Void)?
    
    // init with action for No and Yes button
    public init(actionHandler: ((_ isAccepted: Bool) -> Void)?) {
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(.feedbackIc)
                .resizable()
                .frame(width: 24, height: 24)
            Text("Please let us know your feeling")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primaryText)
            HStack(spacing: 24) {
                Button(action: {
                    actionHandler?(false)
                }) {
                    Text("No")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
                Button(action: {
                    actionHandler?(true)
                }) {
                    Text("Yes")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.AppTemplateMainGradient)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                }
        }
    }
}

#Preview {
    SupportBannerView(actionHandler: nil)
}
