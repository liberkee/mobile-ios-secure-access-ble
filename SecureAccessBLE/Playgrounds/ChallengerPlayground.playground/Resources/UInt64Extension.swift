//
//  UInt64Extension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 02/09/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

/** array of bytes */
public extension UInt64 {
    func bytes(totalBytes: Int = sizeof(UInt64)) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }

    static func withBytes(bytes: ArraySlice<UInt8>) -> UInt64 {
        return UInt64.withBytes(Array(bytes))
    }

    /** Int with array bytes (little-endian) */
    static func withBytes(bytes: [UInt8]) -> UInt64 {
        return integerWithBytes(bytes)
    }
}
