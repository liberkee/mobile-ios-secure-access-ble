//
//  DoubleExtension.swift
//  Pods
//
//  Created by Hua Duong Nguyen on 11.04.17.
//
//

import Foundation

extension Double {
    /// Formats the double to a human readable localized string in currency style with the given currency symbol.
    ///
    /// - Parameter currencySymbol: The currency symbol to use.
    /// - Returns: A localized string representation of a currency value.
    public func toString(currencySymbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol

        // The else case may not be reachable at all
        return formatter.string(from: NSNumber(value: self)) ?? "\(currencySymbol) \(self)"
    }
}
