//
//  CryptoHash.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 07/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

public enum Hash {
    case md5(NSData)
    case sha1(NSData)
    case sha224(NSData), sha256(NSData), sha384(NSData), sha512(NSData)
    case crc32(NSData)

    public func calculate() -> NSData? {
        switch self {
        case let md5(data):
            return MD5(data).calculate()
        case let sha1(data):
            return SHA1(data).calculate()
        case let sha224(data):
            return SHA2(data, variant: .sha224).calculate32()
        case let sha256(data):
            return SHA2(data, variant: .sha256).calculate32()
        case let sha384(data):
            return SHA2(data, variant: .sha384).calculate64()
        case let sha512(data):
            return SHA2(data, variant: .sha512).calculate64()
        case let crc32(data):
            return CRC().crc32(data)
        }
    }
}
