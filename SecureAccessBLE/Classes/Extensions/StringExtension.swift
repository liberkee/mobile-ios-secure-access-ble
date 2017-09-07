//
//  StringExtension.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

// MARK: - Extension end point for String
extension String {
    /**
     Extension String to ensure Creating NSData from hexadecimal string representation, This takes a hexadecimal representation and creates a NSData object.
     Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too.
     This does no validation of the string to ensure it's a valid hexadecimal string

     The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826

     - returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
     */
    func dataFromHexadecimalString() -> Data? {
        let trimmedString = trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them

        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

        let found = regex.firstMatch(in: trimmedString, options: [], range: NSMakeRange(0, trimmedString.characters.count))
        if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
            return nil
        }
        // everything ok, so now let's build NSData
        let data = NSMutableData(capacity: trimmedString.characters.count / 2)
        for index in stride(from: 0, to: trimmedString.characters.distance(from: trimmedString.startIndex, to: trimmedString.endIndex), by: 2) {
            let subStringRange = trimmedString.characters.index(trimmedString.startIndex, offsetBy: index) ..< trimmedString.characters.index(trimmedString.startIndex, offsetBy: index + 2)
            let byteString = trimmedString.substring(with: subStringRange)
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append([num] as [UInt8], length: 1)
        }
        return data as Data?
    }
}
