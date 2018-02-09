//
//  CustomPadding.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

import CryptoSwift
import Foundation

/**
 *  Extensions endpoints for Padding
 */
struct ZeroByte: Padding {
    /**
     To add bytes to current padding

     - parameter bytes:     new padding bytes should be added
     - parameter blockSize: size of block

     - returns: new padding object
     */
    func add(to bytes: [UInt8], blockSize: Int) -> [UInt8] {
        guard bytes.count > 0 else { return bytes }
        let paddingCount = blockSize - (bytes.count % blockSize)
        if paddingCount > 0 {
            return bytes + [UInt8](repeating: 0, count: paddingCount)
        }
        return bytes
    }

    /**
     To remove bytes from current padding

     - parameter bytes:     the bytes should be removed
     - parameter blockSize: size of block

     - returns: new padding object after remove
     */
    func remove(from bytes: [UInt8], blockSize _: Int?) -> [UInt8] {
        var cleanBytes = bytes

        for _ in bytes where cleanBytes.last == 0 {
            cleanBytes.removeLast()
        }
        return cleanBytes
    }
}

/**
 *  Zero Padding with target Length
 */
struct ZeroByteWithLength: Padding {
    fileprivate var length: UInt8 = 0

    /**
     Initialization point

     - parameter length: lenth the padding object should have

     - returns: padding object
     */
    init(length: UInt8) {
        self.length = length
    }

    /**
     To add bytes to current padding

     - parameter bytes:     new padding bytes should be added
     - parameter blockSize: size of block

     - returns: new padding object
     */
    func add(to bytes: [UInt8], blockSize _: Int) -> [UInt8] {
        var withPadding = bytes
        for _ in 0 ..< length {
            withPadding.append(UInt8(0))
        }
        return withPadding
    }

    /**
     To remove bytes from current padding

     - parameter bytes:     the bytes should be removed
     - parameter blockSize: size of block

     - returns: new padding object after remove
     */
    func remove(from bytes: [UInt8], blockSize _: Int?) -> [UInt8] {
        var cleanBytes = bytes
        for _ in 0 ..< length {
            cleanBytes.removeLast()
        }
        return cleanBytes
    }
}

/**
 *  Empty Padding with removed bytes
 */
struct NoPadding: Padding {
    /**
     To add bytes to current padding

     - parameter bytes:     new padding bytes should be added
     - parameter blockSize: size of block

     - returns: new padding object as ifself
     */
    func add(to bytes: [UInt8], blockSize _: Int) -> [UInt8] {
        return bytes
    }

    /**
     To remove bytes from current padding

     - parameter bytes:     the bytes should be removed
     - parameter blockSize: size of block

     - returns: new padding object after remove as ifself
     */
    func remove(from bytes: [UInt8], blockSize _: Int?) -> [UInt8] {
        return bytes
    }
}
