//
//  Logger.swift
//  SmartSubscription
//
//  Created by Harley Pham on 04/05/2024.
//

import Foundation
import os

// define a logger
let logger = Logger(subsystem: "SmartSubscription", category: "")
public struct Log {
    public enum Category: String {
        case main
        case iap
    }
    
    public static func initialize(category: Category) -> Logger {
        return Logger(subsystem: "SmartSubscription", category: category.rawValue)
    }
}
