//
//  ZeroPadding.swift
//  HSM
//
//  Created by Sebastian Stüssel on 18.09.15.
//  Copyright © 2015 Sebastian Stüssel. All rights reserved.
//

import Foundation
import CryptoSwift

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
    func add(to: [UInt8], blockSize: Int) -> [UInt8] {
        let padding = blockSize - to.count
        var withPadding = to
        for _ in 0 ..< padding {
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
    func remove(from: [UInt8], blockSize _: Int?) -> [UInt8] {
        var cleanBytes = from

        for _ in from where cleanBytes.last == 0 {
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
    func add(to: [UInt8], blockSize _: Int) -> [UInt8] {
        var withPadding = to
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
    func remove(from: [UInt8], blockSize _: Int?) -> [UInt8] {
        var cleanBytes = from
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
    func add(to: [UInt8], blockSize _: Int) -> [UInt8] {
        return to
    }

    /**
     To remove bytes from current padding

     - parameter bytes:     the bytes should be removed
     - parameter blockSize: size of block

     - returns: new padding object after remove as ifself
     */
    func remove(from: [UInt8], blockSize _: Int?) -> [UInt8] {
        return from
    }
}
