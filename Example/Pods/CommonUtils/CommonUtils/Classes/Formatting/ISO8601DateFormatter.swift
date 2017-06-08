//
//  ISO8601DateFormatter.swift
//  CommonUtils
//
//  Created by Torsten Lehmann on 27.03.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A ISO8601 date formatter with minutes as the smallest time unit, always in GMT
public class ISO8601DateFormatter {

    private let dateFormatter: DateFormatter

    /// Public initializer
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mmXXXXX"
    }

    /**
     Converts a date to a string
     - parameter date: The date to convert to a string
     - returns: A string in IS08601 date format
     */
    public func string(from date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    /**
     Converts a string to a date
     - parameter string: The string to convert to a date
     - returns: A date or nil if conversion was not possible
     */
    public func date(from string: String) -> Date? {
        return dateFormatter.date(from: string)
    }
}
