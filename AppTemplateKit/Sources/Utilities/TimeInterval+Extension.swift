//
//  TimeInterval+Extension.swift
//  AppTemplatKit
//
//  Created by Harley Pham on 12/10/24.
//

import Foundation

extension TimeInterval {
    public var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? "00:00:00"
    }
}
