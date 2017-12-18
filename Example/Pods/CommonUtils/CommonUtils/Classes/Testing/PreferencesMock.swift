//
//  PreferencesMock.swift
//  CommonUtils
//
//  Created on 01.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A mock for the `PreferencesType` protocol
public class PreferencesMock: PreferencesType {

    var items = [String: Any]()

    public init() {}

    public func bool(forKey key: String) -> Bool? {
        return items[key] as? Bool
    }

    public func setBool(_ value: Bool?, forKey key: String) {
        items[key] = value
    }

    public func string(forKey key: String) -> String? {
        return items[key] as? String
    }

    public func setString(_ value: String?, forKey key: String) {
        items[key] = value
    }

    public func commit() {}
}
