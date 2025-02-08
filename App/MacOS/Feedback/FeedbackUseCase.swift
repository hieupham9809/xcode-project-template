//
//  FeedbackUseCase.swift
//  AppTemplate
//
//  Created by Thanh Phong on 22/12/24.
//

import SwiftUI

final class FeedbackUseCase {
    @AppStorage("com.swiftclean.feedbackPopupViewCount-2")
    var feedbackPopupViewCount: Int?

    /// The most recent app version that prompts for a review.
    @AppStorage("lastVersionPromptedForReview")
    private var lastVersionPromptedForReview = ""

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var shouldRequestReview: Bool {
        currentAppVersion != lastVersionPromptedForReview
    }

    func shouldShowFeedbackPopup() -> Bool {
        if let count = feedbackPopupViewCount, count < 3 {
            self.feedbackPopupViewCount = count + 1
            return false
        }
        else if shouldRequestReview {
            // do nothing, show feedback next time
            return false
        }
        else {
            self.feedbackPopupViewCount = 1
            // display feedback popup
            return true
        }
    }

    func didRequestReview() {
        lastVersionPromptedForReview = currentAppVersion
    }
}
