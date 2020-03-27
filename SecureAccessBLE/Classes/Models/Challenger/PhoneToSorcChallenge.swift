//
//  PhoneToSorcChallenge.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 A SorcMessage Payload for a BLE challenger

 A convience initializer accepts a LeaseToken and a challenge.
 */
struct PhoneToSorcChallenge: SorcMessagePayload {
    /// The initialized data object
    var data: Data = Data()

    /**
     The Device ID as a string.
     Read-only, can be only set through a initializer.
     */
    var leaseID: String {
        let part = data.subdata(in: 0 ..< 36) // 36 chars
        if let deviceID = NSString(data: part, encoding: String.Encoding.utf8.rawValue) {
            return deviceID as String
        } else {
            return ""
        }
    }

    /**
     The SORC id as a string.
     Read-only, can be only set through a initializer.
     */
    var sorcID: SorcID? {
        let part = data.subdata(in: 36 ..< 72) // 36 chars
        return String(data: part, encoding: .utf8).flatMap { UUID(uuidString: $0) }
    }

    /**
     The LeaseToken ID as a string.
     Read-only, can be only set through a initializer.
     */
    var leaseTokenID: String {
        let part = data.subdata(in: 72 ..< 108) // 36 chars
        if let sorcID = NSString(data: part, encoding: String.Encoding.utf8.rawValue) {
            return sorcID as String
        } else {
            return ""
        }
    }

    /**
     The challenge that should be send.
     */
    var challenge: [UInt8] {
        let part = data.subdata(in: 108 ..< 124) // 128 bits
        let challenge = part.bytes
        return challenge
    }

    /**
     Inits the Payload. Takes IDs and challenge directly.
     - parameter deviceID: The Device ID as String
     - parameter sorcID: The SORC ID as String
     - parameter leaseTokenID: The LeaseToken ID as String
     - parameter challenge: The challenge as a UInt8 array

     */
    init(leaseID: String, sorcID: SorcID, leaseTokenID: String, challenge: [UInt8]) {
        var data = Data()

        if let stringData = leaseID.data(using: .utf8) {
            data.append(stringData)
        }
        if let stringData = sorcID.lowercasedUUIDString.data(using: .utf8) {
            data.append(stringData)
        }

        let lowerCaseTokenID = leaseTokenID.lowercased()
        if let stringData = lowerCaseTokenID.data(using: .utf8) {
            data.append(stringData)
        }
        data.append(challenge, count: challenge.count)
        self.data = data as Data
    }
}
