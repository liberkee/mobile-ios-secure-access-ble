//
//  StringExtension.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 15/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

/** String extension */
public extension String {
    /** Calculate MD5 hash */
    func md5() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.md5()?.toHexString()
    }

    func sha1() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.sha1()?.toHexString()
    }

    func sha224() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.sha224()?.toHexString()
    }

    func sha256() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.sha256()?.toHexString()
    }

    func sha384() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.sha384()?.toHexString()
    }

    func sha512() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.sha512()?.toHexString()
    }

    func crc32() -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.crc32()?.toHexString()
    }

    func encrypt(cipher: Cipher) throws -> String? {
        return try dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.encrypt(cipher)?.toHexString()
    }

    func decrypt(cipher: Cipher) throws -> String? {
        return try dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.decrypt(cipher)?.toHexString()
    }

    func authenticate(authenticator: Authenticator) -> String? {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.authenticate(authenticator)?.toHexString()
    }
}
