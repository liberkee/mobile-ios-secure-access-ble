//
//  DateExtension.swift
//  CommonUtils
//
//  Created on 11.04.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

extension Date {
    /// Formats the date to a human readable localized string with optional date and time styles.
    ///
    /// - Parameters:
    ///   - dateStyle: The date style to use. Defaults to `medium`.
    ///   - timeStyle: The time style to use. Defaults to `short`.
    /// - Returns: A localized string representation with the given date and time styles.
    public func toString(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle

        return formatter.string(from: self)
    }
}
