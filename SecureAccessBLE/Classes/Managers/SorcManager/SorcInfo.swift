//
//  SorcInfo.swift
//  SecureAccessBLE
//
//  Created on 11.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

/// Container for information related to a sorc
public struct SorcInfo: Equatable {
    /// Sorc id
    public let sorcID: SorcID
    /// Discovery date
    public let discoveryDate: Date
    /// RSSI value
    public let rssi: Int

    /// Initalizer for `SorcInfo`
    ///
    /// - Parameters:
    ///   - sorcID: sorc id
    ///   - discoveryDate: discovery date
    ///   - rssi: rssi value
    public init(sorcID: SorcID, discoveryDate: Date, rssi: Int) {
        self.sorcID = sorcID
        self.discoveryDate = discoveryDate
        self.rssi = rssi
    }

    public static func == (lhs: SorcInfo, rhs: SorcInfo) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.discoveryDate == rhs.discoveryDate
            && lhs.rssi == rhs.rssi
    }
}
