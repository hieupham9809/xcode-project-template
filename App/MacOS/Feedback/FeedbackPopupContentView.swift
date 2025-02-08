//
//  FeedbackPopupContentView.swift
//  SwiftClean
//
//  Created by Harley Pham on 4/8/24.
//
// Utilizing PopupViewContainer to display a feedback popup view.

import AppTemplateKit
import SwiftUI

struct FeedbackPopupContentView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 0) {
                Text("Like it? You can give us feedback at ")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                Button {
                    URL(string: Support.Banner.url).map { openURL($0) }
                } label: {
                    Text("here")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.AppTemplateMainGradient)
                }
                .buttonStyle(PlainButtonStyle())
            }
#if APP_SANDBOX
            .padding(.bottom, 32)
#endif
#if !APP_SANDBOX
            Text("Or you can support us by:")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.primaryText)

            HStack(spacing: 32) {
                SupportPaypalButton()
                SupportBuymeacoffeeButton()
            }
            .padding(.bottom, 32)
#endif
        }
    }
}

#Preview {
    PopupViewContainer(isPresented: .constant(true), content: { FeedbackPopupContentView() })
}
