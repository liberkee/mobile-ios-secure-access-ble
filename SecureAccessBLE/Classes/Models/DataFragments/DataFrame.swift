//
//  DataFrame.swift
//  SecureAccessBLE
//
//  Created on 03.10.16.
//  Copyright © 2016 Huf Secure Mobile GmbH. All rights reserved.
//

/**
 Defines all used message fragments types in enumerating
 */
enum DataFrameType: UInt8 {
    /// Has fraements length
    case frag = 0x00
    /// Has total length
    case sop = 0x01
    /// Has fraements length
    case eop = 0x02
    /// Single frame
    case single = 0x03
    /// does not need to be acked: special SOP|EOP
    case ack = 0x0B
    /// special SOP|EOP
    case noAck = 0x07
    /// NotValid
    case notValid = 0xFF
}

/**
 *  The transport layer frame will be built here.
 *  Depending on the type of fragment the transport layer frame has different layout.
 *  It can be signaled in MSG_PROP if an ACK is expected from the peer and
 *  if that is per fragment or per frame.
 */
struct DataFrame {
    /// Data frame type, see definition obove
    var type: DataFrameType {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, count: 1)
        if let validValue = DataFrameType(rawValue: byteArray[0] >> 4) {
            return validValue
        } else {
            return .notValid
        }
    }

    /// If ACKnowledgement needed or not as Bool
    var ackNeeded: Bool {
        let ackFlag: UInt8 = 0x01 << 1
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, count: 1)
        guard let flag = byteArray.first else {
            return false
        }
        if flag & ackFlag == 1 {
            return true
        } else {
            return false
        }
    }

    /// Sequence Number (SN) needed to handle retransmissions and lost TL_ACK, NACK
    /// SN will be limited to 1 byte so that it will wrap around after 255 back to 0
    var sequenceNumber: UInt8 {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, from: 1 ..< 2)
        return byteArray[0]
    }

    /// The length as UInt16
    var length: UInt16 {
        var byteArray = [UInt8](repeating: 0x0, count: 1)
        (data as Data).copyBytes(to: &byteArray, from: 2 ..< 4)
        let u16 = UnsafePointer(byteArray).withMemoryRebound(to: UInt16.self, capacity: 1) {
            $0.pointee
        }
        return u16 // (UnsafePointer<UInt16>(byteArray)).pointee
    }

    /// Message data that will be ranported through TL-frame
    var message: Data {
        if data.count < 4 {
            return Data()
        }
        let msg = data.subdata(in: 4 ..< data.count) // NSMakeRange(4, data.count-4))
        return msg
    }

    /// Start data as NSData
    let data: Data

    /**
     Initialization point

     - parameter rawData: incomming raw data

     - returns: data frame object
     */
    init(rawData: Data) {
        data = rawData
    }

    /**
     Init end point for TL-message fragments

     - parameter message:               message data to transport
     - parameter type:                  data frame type
     - parameter sequenceNumber:        needed for retranporting
     - parameter completeMessageLength: message length

     - returns: self object as Transport layer message fragments
     */
    init(message: Data, type: DataFrameType, sequenceNumber: UInt8, completeMessageLength: UInt16) {
        let frameData = NSMutableData()
        var typeByte = type.rawValue << 4
        var sequence = sequenceNumber
        var messageLength: UInt16!
        if type == .sop {
            messageLength = UInt16(completeMessageLength)
        } else {
            messageLength = UInt16(message.count)
        }

        frameData.append(&typeByte, length: 1)
        frameData.append(&sequence, length: 1)
        frameData.append(&messageLength, length: 2)
        frameData.append(message)
        data = frameData as Data
    }
}
