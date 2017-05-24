//
//  Extensions.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 24.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public extension Array where Element: AnyObject {

    public mutating func removeObject(_ object: Element) {
        if let index = index(where: { $0 === object }) {
            remove(at: index)
        }
    }
}
