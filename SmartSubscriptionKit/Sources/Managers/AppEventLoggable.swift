//
//  AppEventLoggable.swift
//
//
//  Created by Phong Tran 2 on 12/9/24.
//

import Foundation

public protocol AppEventLoggable {
    func log(eventName: String, params: [String: Any]) async throws
}
