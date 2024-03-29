//
//  StringExtensions.swift
//  CommonUtils
//
//  Created on 19.09.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public extension String {
    /**
     Extension String to ensure Creating Data from hexadecimal string representation, This takes a hexadecimal representation
     and creates a Data object.
     Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too.
     This does no validation of the string to ensure it's a valid hexadecimal string

     The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826

     - returns: Data represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
     */
    func dataFromHexadecimalString() -> Data? {
        let trimmedString = trimmingCharacters(in: CharacterSet(charactersIn: "<> "))
            .replacingOccurrences(of: " ", with: "")
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them

        var regex = NSRegularExpression()

        do {
            regex = try NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
        } catch {
            HSMLog(message: "\(error)", level: .error)
        }

        let range = NSRange(location: 0, length: trimmedString.count)
        let found = regex.firstMatch(in: trimmedString, options: [], range: range)
        if found == nil || found?.range.location == NSNotFound || trimmedString.count % 2 != 0 {
            return nil
        }
        // everything ok, so now let's build NSData
        let data = NSMutableData(capacity: trimmedString.count / 2)
        for index in stride(from: 0, to: trimmedString
            .distance(from: trimmedString.startIndex, to: trimmedString.endIndex), by: 2)
        {
            let subStringRange = trimmedString.index(trimmedString.startIndex, offsetBy: index)
                ..< trimmedString.index(trimmedString.startIndex, offsetBy: index + 2)
            let byteString = trimmedString[subStringRange]
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append([num] as [UInt8], length: 1)
        }
        return data as Data?
    }
}
