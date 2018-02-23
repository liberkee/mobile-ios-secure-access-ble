//
//  StringStorage.swift
//  CommonUtils
//
//  Created on 16.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Defines methods that a `StringStorageType` must conform to
public protocol StringStorageType {
    /// Loads a string from the file system
    ///
    /// - Returns: The saved string or nil if does not exist
    ///
    func load() -> String?

    /// Saves a string to the file system
    ///
    /// - Parameter string: The string to save
    /// - Throws: An error if the string could not be saved.
    ///
    func save(_ string: String) throws

    /// Removes the storage from the file system
    ///
    /// - Throws: An error if the storage could not be removed.
    func remove() throws
}

/// A storage for a `String` on the local file system
class StringStorage: StringStorageType {
    /// The url of the file
    private let fileURL: URL

    /// Initializes a `StringStorage`
    ///
    /// - Parameter fileURL: The url of the storage file
    ///
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() -> String? {
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    func save(_ string: String) throws {
        try string.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func remove() throws {
        try FileManager.default.removeItem(at: fileURL)
    }
}
