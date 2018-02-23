//
//  DataExtensions.swift
//  CommonUtils
//
//  Created on 01.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension Data {
    /// Converts the data to a UUID string in lowercased format with hyphens if possible. Otherwise it returns nil.
    public var uuidString: String? {
        guard count == 16 else { return nil }

        // taken from: https://gist.github.com/DonaldHays/e5dc53c89e5abfe866f0

        var output = ""

        for (index, byte) in enumerated() {
            let nextCharacter = String(byte, radix: 16)
            if nextCharacter.count == 2 {
                output += nextCharacter
            } else {
                output += "0" + nextCharacter
            }

            if [3, 5, 7, 9].index(of: index) != nil {
                output += "-"
            }
        }

        return output
    }
}
