//
//  ArrayExtensions.swift
//  CommonUtils
//
//  Created on 24.05.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

extension Array where Element: AnyObject {
    /**
     Removes an object from this array by comparing references

     - parameter object: The object to remove
     */
    mutating func removeObject(_ object: Element) {
        if let index = index(where: { $0 === object }) {
            remove(at: index)
        }
    }
}
