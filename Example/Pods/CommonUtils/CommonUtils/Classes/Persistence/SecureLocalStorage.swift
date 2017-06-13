//
//  SecureLocalStorage.swift
//  CommonUtils
//
//  Created by Torsten Lehmann on 13.03.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// A LocalStorage that stores data as JSON formatted string in the iOS keychain
public class SecureLocalStorage: LocalStorage {

    // The key under which data is stored in the keychain
    private let keychainKey: String

    // A wrapper around keychain handling
    private var securePreferences: SecurePreferencesType

    /**
     Initialize the local storage with a key used for the keychain

     - parameter keychainKey: The key under which the data is stored in the keychain
     - parameter securePreferences: The secure preferences to store the data in
     */
    public init(keychainKey: String, securePreferences: SecurePreferencesType) {
        self.keychainKey = keychainKey
        self.securePreferences = securePreferences
    }

    /**
     Loads the locally saved data as object

     - returns: The saved object or `nil` if it doesn't exist
     */
    public func loadObject<T: Mappable>() -> T? {
        if let json = securePreferences[keychainKey] {
            return Mapper<T>().map(JSONString: json)
        } else {
            return nil
        }
    }

    /**
     Loads the locally saved data as array

     - returns: The saved array or `nil` if it doesn't exist
     */
    public func loadArray<T: Mappable>() -> [T]? {
        if let json = securePreferences[keychainKey] {
            return Mapper<T>().mapArray(JSONString: json)
        } else {
            return nil
        }
    }

    /**
     Saves an object locally in a json format

     - parameter object: The object to be saved locally
     - returns: `true` if saving succeeds or `false` otherwise
     */
    public func save<T: Mappable>(_ object: T) -> Bool {
        if let json = Mapper().toJSONString(object, prettyPrint: true) {
            return saveJSON(json)
        } else {
            debugPrint("Local JSON Storage (\(keychainKey)): Error while serializing object to JSON")
            return false
        }
    }

    /**
     Saves an array locally in a json format

     - parameter array: The array to be saved locally
     - returns: `true` if saving succeeds or `false` otherwise
     */
    public func save<T: Mappable>(_ array: [T]) -> Bool {
        if let json = Mapper().toJSONString(array, prettyPrint: true) {
            return saveJSON(json)
        } else {
            debugPrint("Local JSON Storage (\(keychainKey)): Error while serializing array to JSON")
            return false
        }
    }

    /**
     Deletes the local storage from the keychain

     - returns: `true` if deleting succeeds or `false` otherwise
     */
    public func delete() -> Bool {
        do {
            try securePreferences.remove(keychainKey)
            return true
        } catch {
            debugPrint("Local JSON Storage (\(keychainKey)): Error while deleting JSON file")
            return false
        }
    }

    // MARK: Private helper functions

    /**
     Writes a JSON string to file

     - parameter json: The JSON string to save
     - returns: `true` if saving succeeds or `false` otherwise
     */
    fileprivate func saveJSON(_ json: String) -> Bool {
        securePreferences[keychainKey] = json
        return true
    }
}
