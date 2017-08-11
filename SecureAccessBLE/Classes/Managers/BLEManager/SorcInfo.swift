//
//  SorcInfo.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 09.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

public struct SorcInfo: Equatable {

    public let sorcID: String
    public let discoveryDate: Date
    public let rssi: Int

    public init(sorcID: String, discoveryDate: Date, rssi: Int) {
        self.sorcID = sorcID
        self.discoveryDate = discoveryDate
        self.rssi = rssi
    }

    public static func ==(lhs: SorcInfo, rhs: SorcInfo) -> Bool {
        return lhs.sorcID == rhs.sorcID
            && lhs.discoveryDate == rhs.discoveryDate
            && lhs.rssi == rhs.rssi
    }
}
