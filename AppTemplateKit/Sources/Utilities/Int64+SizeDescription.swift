//
//  Int64+SizeDescription.swift
//
//
//  Created by Harley Pham on 26/05/2024.
//

import Foundation

public extension Int64 {
    var sizeDescription: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
