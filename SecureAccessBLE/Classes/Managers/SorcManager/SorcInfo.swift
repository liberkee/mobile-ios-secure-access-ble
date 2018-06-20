//
//  SorcInfo.swift
//  SecureAccessBLE
//
//  Created on 11.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

/// Container for information related to a SORC
public struct SorcInfo: Equatable {
    /// The ID of the SORC
    public let sorcID: SorcID

    /// The date on which the SORC was discovered
    public let discoveryDate: Date

    /// The received signal strength indicator
    public let rssi: Int

    /// :nodoc:
    public init(sorcID: SorcID, discoveryDate: Date, rssi: Int) {
        self.sorcID = sorcID
        self.discoveryDate = discoveryDate
        self.rssi = rssi
    }

    /// :nodoc:
    public static func == (lhs: SorcInfo, rhs: SorcInfo) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.discoveryDate == rhs.discoveryDate
            && lhs.rssi == rhs.rssi
    }
}
