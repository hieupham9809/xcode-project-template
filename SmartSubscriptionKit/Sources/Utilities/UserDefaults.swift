//
//  UserDefaults.swift
//
//
//  Created by Harley Pham on 4/8/24.
//  A property wrapper that allows you to store a value in UserDefaults by providing a key.

import Foundation

@propertyWrapper
public struct UserDefaultsBacked<Value> {
    let key: String
    let defaultValue: Value
    
    public init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: Value {
        get {
            return UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}


