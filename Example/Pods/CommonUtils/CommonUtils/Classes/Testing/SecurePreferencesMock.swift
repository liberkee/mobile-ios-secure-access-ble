//
//  SecurePreferencesMock.swift
//  CommonUtils
//
//  Created on 13.03.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Mocks the communication with the keychain
public class SecurePreferencesMock: SecurePreferencesType {
    struct PreferencesError: Error {}

    var items = [String: String]()
    var shouldThrow = false

    /// Public initializer
    public init() {}

    /**
     A subscript to get and set a string with a `key`

     - parameter key: The key of the string to get or set. Remove an item by passing `nil` as value.
     - returns: A string for the given `key` or `nil` if it doesn't exist
     */
    public subscript(key: String) -> String? {
        get {
            return items[key]
        }
        set {
            items[key] = newValue
        }
    }

    /// Remove the item with `key` from the keychain
    public func remove(_ key: String) throws {
        if shouldThrow {
            throw PreferencesError()
        }
        items.removeValue(forKey: key)
    }

    /// Resets all items in the keychain set by this application
    public func resetKeychain() {
        items = [:]
    }
}
