//
//  LocalJSONStorage.swift
//  CommonUtils
//
//  Created on 13.03.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// A JSON implementation of a local storage for saving data in JSON files
public struct LocalJSONStorage: LocalStorage {

    /// The storage used for file access
    private let stringStorage: StringStorageType

    /**
     Initialize the local JSON storage with a url where it should be saved

     - parameter jsonURL: The url of the JSON storage
     */
    public init(jsonURL: URL) {
        self.init(stringStorage: StringStorage(fileURL: jsonURL))
    }

    /**
     Initialize the local JSON storage with a `StringStorage` that handles file access

     - parameter stringStorage: The `StringStorage` to use
     */
    public init(stringStorage: StringStorageType) {
        self.stringStorage = stringStorage
    }

    /**
     Loads the locally saved data as object

     - parameter object: The object to be saved locally
     - returns: The saved object or `nil` if it doesn't exist
     */
    public func loadObject<T: BaseMappable>(context: MapContext? = nil) -> T? {
        if let json = stringStorage.load() {
            return Mapper<T>(context: context).map(JSONString: json)
        } else {
            return nil
        }
    }

    /**
     Loads the locally saved data as array

     - returns: The saved array or `nil` if it doesn't exist
     */
    public func loadArray<T: BaseMappable>() -> [T]? {
        if let json = stringStorage.load() {
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
    public func save<T: BaseMappable>(_ object: T) -> Bool {
        if let json = Mapper().toJSONString(object, prettyPrint: true) {
            return saveJSON(json)
        } else {
            HSMLog(message: "Local JSON Storage: Error while serializing object to JSON", level: .error)
            return false
        }
    }

    /**
     Saves an array locally in a json format

     - parameter array: The array to be saved locally
     - returns: `true` if saving succeeds or `false` otherwise
     */
    public func save<T: BaseMappable>(_ array: [T]) -> Bool {
        if let json = Mapper().toJSONString(array, prettyPrint: true) {
            return saveJSON(json)
        } else {
            HSMLog(message: "Local JSON Storage: Error while serializing array to JSON", level: .error)
            return false
        }
    }

    /**
     Deletes the locally stored JSON file

     - returns: `true` if deleting succeeds or `false` otherwise
     */
    public func delete() -> Bool {
        do {
            try stringStorage.remove()
            return true
        } catch {
            HSMLog(message: "Local JSON Storage: Error while deleting JSON file", level: .error)
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
        do {
            try stringStorage.save(json)
            return true
        } catch {
            HSMLog(message: "Local JSON Storage: Error while saving to JSON file", level: .error)
            return false
        }
    }
}
