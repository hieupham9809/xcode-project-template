//
//  Weak.swift
//  DevCleaner
//
//  Created by Konrad Kołakowski on 03/10/2018.
//  Copyright © 2018 One Minute Games. All rights reserved.
//

import Foundation

public class Weak<T: AnyObject>: Equatable {
    public private(set) weak var value: T?
    
    init(value: T?) {
        self.value = value
    }
    
    public static func == (lhs: Weak<T>, rhs: Weak<T>) -> Bool {
        return lhs.value === rhs.value
    }
}

public class WeakCollection {
    public init() {}
    private(set) var weakItems = NSHashTable<AnyObject>.weakObjects()
    public func add(_ item: AnyObject) {
        weakItems.add(item)
    }

    public func remove(_ item: AnyObject) {
        weakItems.remove(item)
    }
}
