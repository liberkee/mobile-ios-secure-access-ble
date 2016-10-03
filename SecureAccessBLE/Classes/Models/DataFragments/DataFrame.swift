//
//  DataFrame.swift
//  TransportTest
//
//  Created by Sebastian Stüssel on 20.08.15.
//  Copyright (c) 2015 Rocket Apes. All rights reserved.
//
import UIKit

/**
 Defines all used message fragments types in enumerating
 */
enum DataFrameType: UInt8 {
    /// Has fraements length
    case Frag = 0x00
    /// Has total length
    case Sop = 0x01
    /// Has fraements length
    case Eop = 0x02
    /// Single frame
    case Single = 0x03
    /// does not need to be acked: special SOP|EOP
    case Ack = 0x0b
    /// special SOP|EOP
    case NoAck = 0x07
    /// NotValid
    case NotValid = 0xFF
}

/**
 *  The transport layer frame will be builed here.
 *  Depending on the type of fragment the transport layer frame has different layout.
 *  It can be signalled in MSG_PROP if an ACK is expected from the peer and 
 *  if that is per fragment or per frame.
 */
struct DataFrame {
    
    /// Data frame type, see definition obove
    var type: DataFrameType {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, length:1)
        if let validValue = DataFrameType(rawValue: byteArray[0]>>4) {
            return validValue
        } else {
            return .NotValid
        }
    }
    
    /// If ACKnowledgement need or not as Bool
    var ackNeeded: Bool {
        let ackFlag:UInt8 = 0x01<<1
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, length:1)
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
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, range: NSMakeRange(1, 1))
        return byteArray[0]
    }
    
    /// The length as UInt16
    var length: UInt16 {
        var byteArray = [UInt8](count: 1, repeatedValue: 0x0)
        data.getBytes(&byteArray, range: NSMakeRange(2, 2))
        return UnsafePointer<UInt16>(byteArray).memory
    }
    
    /// Message data that will be ranported through TL-frame
    var message: NSData {
        if data.length < 4 {
            return NSData()
        }
        let msg = data.subdataWithRange(NSMakeRange(4, data.length-4))
        return msg
    }
    
    /// Start data as NSData
    let data: NSData
    
    /**
     Initialization point
     
     - parameter rawData: incomming raw data
     
     - returns: data frame object
     */
    init(rawData: NSData) {
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
    init(message: NSData, type: DataFrameType, sequenceNumber: UInt8, completeMessageLength:UInt16) {
        let frameData = NSMutableData()
        var typeByte = type.rawValue << 4
        var sequence = sequenceNumber
        var messageLength : UInt16!
        if type == .Sop {
            messageLength = UInt16(completeMessageLength)
        } else {
            messageLength = UInt16(message.length)
        }
        
        frameData.appendBytes(&typeByte, length: 1)
        frameData.appendBytes(&sequence, length: 1)
        frameData.appendBytes(&messageLength, length: 2)
        frameData.appendData(message)
        self.data = frameData
        
    }
}