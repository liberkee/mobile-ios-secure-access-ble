//
//  PhoneToSorcChallenge.swift
//  BLE
//
//  Created by Ke Song on 20.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit

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
    var sorcID: SorcID {
        let part = data.subdata(in: 36 ..< 72) // 36 chars
        if let sorcID = NSString(data: part, encoding: String.Encoding.utf8.rawValue) {
            return sorcID as String
        } else {
            return ""
        }
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
        let data = NSMutableData()

        if let stringData = leaseID.data(using: String.Encoding.utf8) {
            data.append(stringData)
        }
        if let stringData = sorcID.data(using: String.Encoding.utf8) {
            data.append(stringData)
        }

        let lowerCaseTokenID = leaseTokenID.lowercased()
        if let stringData = lowerCaseTokenID.data(using: String.Encoding.utf8) {
            data.append(stringData)
        }
        data.append(challenge, length: challenge.count)
        self.data = data as Data
    }
}
