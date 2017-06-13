//
//  LocalStorage.swift
//  CommonUtils
//
//  Created by Lars Hosemann on 19.05.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation
import ObjectMapper

/// A protocol defining functions for saving data locally
public protocol LocalStorage {

    /**
     Loads the locally saved data as object

     - returns: The saved object or `nil` if it doesn't exist
     */
    func loadObject<T: Mappable>() -> T?

    /**
     Loads the locally saved data as array

     - returns: The saved array or `nil` if it doesn't exist
     */
    func loadArray<T: Mappable>() -> [T]?

    /**
     Saves an object locally

     - parameter object: The object to be saved locally
     - returns: `true` if saving succeeds or `false` otherwise
     */
    func save<T: Mappable>(_ object: T) -> Bool

    /**
     Saves an array locally

     - parameter array: The array to be saved locally
     - returns: `true` if saving succeeds or `false` otherwise
     */
    func save<T: Mappable>(_ array: [T]) -> Bool

    /**
     Deletes the locally stored data

     - returns: `true` if deleting succeeds or `false` otherwise
     */
    func delete() -> Bool
}