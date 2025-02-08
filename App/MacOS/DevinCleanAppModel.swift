//
//  AppTemplateAppModel.swift
//  AppTemplate
//
//  Created by Harley Pham on 3/11/24.
//

import AppTemplateKit
import Foundation
import SwiftUI

final class AppTemplateAppModel {
    static let shared = AppTemplateAppModel()
    
#if APP_SANDBOX
    let isAppSandbox = true
#else
    let isAppSandbox = false
#endif

    private(set) var contentViewModel: ContentViewModel

    private init() {
        contentViewModel = ContentViewModel()
    }
}

final class ContentViewModel {
    // For displayed view
}

final class ViewModelCaching<Value, Data> {
    let shouldReuse: (_ value: Value, _ data: Data) -> Bool
    let generate: (_ data: Data) -> Value?

    @MainActor
    init(
        shouldReuse: @escaping (_ value: Value, _ data: Data) -> Bool,
        generate: @escaping (_ data: Data) -> Value?
    ) {
        self.shouldReuse = shouldReuse
        self.generate = generate
    }

    @MainActor
    func get(with data: Data) -> Value? {
        if let value = value, shouldReuse(value, data) {
            return value
        }

        let newValue = generate(data)
        newValue.map { update($0) }
        return newValue
    }

    @MainActor
    private(set) var value: Value?

    @MainActor
    func update(_ value: Value) {
        self.value = value
    }
}
