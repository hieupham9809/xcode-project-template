//
//  Preferences.swift
//  DevCleaner
//
//  Created by Konrad Kołakowski on 01.05.2018.
//  Copyright © 2018 One Minute Games. All rights reserved.
//
//  DevCleaner is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 3 of the License, or
//  (at your option) any later version.
//
//  DevCleaner is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with DevCleaner.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import CryptoKit

// MARK: Preferences Observer
@objc public protocol PreferencesObserver: AnyObject {
    func preferenceDidChange(key: String)
}

// MARK: - Preferences Class
public final class Preferences {
    // MARK: Keys
    public struct Keys {
        public static let notificationsEnabled = "AppNotificationsEnabledKey"
        public static let notificationsPeriod = "AppNotificationsPeriodKey"

        public static let installID = "AppInstallID"
    }
    
    // MARK: Properties & constants
    public static let shared = Preferences()
    
    private var observers = [Weak<PreferencesObserver>]()

    // MARK: Initialization
    public init() {
        
    }
    
    // MARK: Observers
    public func addObserver(_ observer: PreferencesObserver) {
        let weakObserver = Weak(value: observer)
        
        if !self.observers.contains(weakObserver) {
            self.observers.append(weakObserver)
        }
    }
    
    public func removeObserver(_ observer: PreferencesObserver) {
        let weakObserverToRemove = Weak(value: observer)
        
        self.observers.removeAll { (observer) -> Bool in
            return observer == weakObserverToRemove
        }
    }
    
    private func informAllObserversAboutChange(keyThatChanged: String) {
        for observer in self.observers {
            observer.value?.preferenceDidChange(key: keyThatChanged)
        }
    }
    
    // MARK: Environment
    public func envValue(key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
    
    public func envKeyPresent(key: String) -> Bool {
        return ProcessInfo.processInfo.environment.keys.contains(key)
    }
    
    // MARK: Options
    public var notificationsEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: Keys.notificationsEnabled) != nil else {
                return true // default value
            }
            
            return UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.notificationsEnabled)
            self.informAllObserversAboutChange(keyThatChanged: Keys.notificationsEnabled)
        }
    }

    public var installID: String {
        if let installID = UserDefaults.standard.string(forKey: Keys.installID) {
            return installID
        }

        let installID = UUID().uuidString
        UserDefaults.standard.setValue(installID, forKey: Keys.installID)

        return installID
    }
}
