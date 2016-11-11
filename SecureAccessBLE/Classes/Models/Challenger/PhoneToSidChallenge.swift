//
//  PhoneToSidChallenge.swift
//  BLE
//
//  Created by Ke Song on 20.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit

/**
 A SidMessaage Payload for a BLE challenger
 
 A convience initializer accepts a LeaseToken and a challenge.
 */
struct PhoneToSidChallenge: SIDMessagePayload {
    /// The initialized data object
    var data: Data = Data()
    
    /**
     The Device ID as a string.
     Read-only, can be only set through a initializer.
     */
    var deviceID: String {
        let part = self.data.subdata(in: 0..<36)//NSMakeRange(0, 36))
        if let deviceId = NSString(data: part, encoding: String.Encoding.utf8.rawValue) {
            return deviceId as String
        } else {
            return ""
        }
    }
    
    /**
     The SID ID as a string.
     Read-only, can be only set through a initializer.
     */
    var sidID: String {
        let part = self.data.subdata(in: 36..<72)//NSMakeRange(36, 36))
        if let sidId = NSString(data: part, encoding: String.Encoding.utf8.rawValue) {
            return sidId as String
        } else {
            return ""
        }
    }
    
    /**
     The LeaseToken ID as a string.
     Read-only, can be only set through a initializer.
     */
    var leaseTokenID: String {
        let part = self.data.subdata(in: 72..<152)//NSMakeRange(72, 80))
        if let sidId = NSString(data: part, encoding: String.Encoding.utf8.rawValue) {
            return sidId as String
        } else {
            return ""
        }
    }
    /**
     The challenge that should be send.
     */
    var challenge: [UInt8] {
        let part = self.data.subdata(in: 152..<178)//NSMakeRange(152, 16))
        let challenge = part.bytes//.arrayOfBytes()
        return challenge
    }
    
    /**
     Inits the Payload. Takes IDs and challenge directly.
     - parameter deviceID: The Device ID as String
     - parameter sidID: The SID ID as String
     - parameter leaseTokenID: The LeaseToken ID as String
     - parameter challenge: The challenge as a UInt8 array
     
     */
    init(deviceID: String, sidID: String, leaseTokenID: String, challenge: [UInt8]) {
        let data = NSMutableData()
        
        if let stringData = deviceID.data(using: String.Encoding.utf8) {
            data.append(stringData)
        }
        if let stringData = sidID.data(using: String.Encoding.utf8) {
            data.append(stringData)
        }
        
        let lowerCaseTokenID = leaseTokenID.lowercased()
        if let stringData = lowerCaseTokenID.data(using: String.Encoding.utf8) {
            data.append(stringData)
        }
        data.append(challenge, length: challenge.count)
        self.data = data as Data
        //        print("data:\(data) with length:\(self.data.length)")
    }
    
}