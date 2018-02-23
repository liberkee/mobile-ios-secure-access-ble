//
//  Preferences.swift
//  CommonUtils
//
//  Created on 01.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Describes a type that is used for storing key value pairs persistently
public protocol PreferencesType {
    /**
     Gets a `Bool` value in the preferences under given key.
     If value for given key does not exist, it returns nil.
     */
    func bool(forKey key: String) -> Bool?

    /**
     Sets a `Bool` value in the preferences under given key.
     If set value is nil, the key value pair is removed from preferences.
     */
    func setBool(_ value: Bool?, forKey key: String)

    /**
     Gets a `String` value in the preferences under given key.
     If value for given key does not exist, it returns nil.
     */
    func string(forKey key: String) -> String?

    /**
     Sets a `String` value in the preferences under given key.
     If set value is nil, the key value pair is removed from preferences.
     */
    func setString(_: String?, forKey key: String)

    /**
     Writes the changes to disk
     */
    func commit()
}

/// Stores values in `UserDefaults.standard`
public class Preferences: PreferencesType {
    private let userDefaults: UserDefaults

    /// Inits preferences that write to `UserDefaults.standard`
    public convenience init() {
        self.init(userDefaults: UserDefaults.standard)
    }

    /**
     Inits preferences with given `UserDefaults`
     - parameter userDefaults: The `UserDefaults` to write to
     */
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public func bool(forKey key: String) -> Bool? {
        return userDefaults.object(forKey: key) as? Bool
    }

    public func setBool(_ value: Bool?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    public func string(forKey key: String) -> String? {
        return userDefaults.object(forKey: key) as? String
    }

    public func setString(_ value: String?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func commit() {
        userDefaults.synchronize()
    }
}
