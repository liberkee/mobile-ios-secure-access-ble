//
//  SecurePreferences.swift
//  CommonUtils
//
//  Created on 13.03.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import KeychainAccess

/// Describes the contract to access the keychain
protocol KeychainType {
    /**
     A subscript to get and set a string with a `key`

     - parameter key: The key of the string to get or set
     - returns: A string for the given `key` or `nil` if it doesn't exist
     */
    subscript(_: String) -> String? { get set }

    /// Remove the item with `key` from the keychain
    func remove(_ key: String) throws

    /// Resets all items in the keychain
    func removeAll() throws
}

extension Keychain: KeychainType {}

/// Describes the contract to save security related data to the keychain
public protocol SecurePreferencesType {
    /**
     A subscript to get and set a string with a `key`

     - parameter key: The key of the string to get or set. Remove an item by passing `nil` as value.
     - returns: A string for the given `key` or `nil` if it doesn't exist
     */
    subscript(_: String) -> String? { get set }

    /// Remove the item with `key` from the keychain
    func remove(_ key: String) throws

    /// Resets all items in the keychain set by this application
    func resetKeychain()
}

/// Saves security related data to the keychain
public class SecurePreferences: SecurePreferencesType {
    private let clearedKeychainOnFirstRunKey = "clearedKeychainOnFirstRunKey"

    private var keychain: KeychainType
    private let preferences: PreferencesType

    /**
     A subscript to get and set a string with a `key`

     - parameter key: The key of the string to get or set
     - returns: A string for the given `key` or `nil` if it doesn't exist
     */
    public subscript(key: String) -> String? {
        get {
            return keychain[key]
        }
        set {
            keychain[key] = newValue
        }
    }

    /// Inits an instance and resets all items in the keychain set by this app on first run of the app
    public convenience init() {
        self.init(keychain: Keychain(), preferences: Preferences())
    }

    /**
     Inits an instance and resets all items in the keychain set by this app on first run of the app
     - parameter keychain: The keychain to use
     - parameter preferences: The preferences to use
     */
    init(keychain: KeychainType, preferences: PreferencesType) {
        self.keychain = keychain
        self.preferences = preferences
        resetKeychainOnFirstRun()
    }

    /// Remove the item with `key` from the keychain
    public func remove(_ key: String) throws {
        try keychain.remove(key)
    }

    /// Resets all items in the keychain set by this application
    public func resetKeychain() {
        try? keychain.removeAll()
    }

    /// Resets the all items in the keychain set by this app on first run of the app
    private func resetKeychainOnFirstRun() {
        let clearedKeychain = preferences.bool(forKey: clearedKeychainOnFirstRunKey) ?? false
        guard !clearedKeychain else { return }
        resetKeychain()
        preferences.setBool(true, forKey: clearedKeychainOnFirstRunKey)
        preferences.commit()
    }
}
