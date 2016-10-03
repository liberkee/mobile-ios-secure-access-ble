//
//  SIDCommunicator.swift
//  BLE
//
//  Created by Ke Song on 24.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation

/**
 *  SIDCommnicator takes a communication to SID and handles the response from SID.
 *  Sending and receiving message through data transfer (Scanner)
 */
protocol SIDCommunicatorDelegate {
    /**
     Communicator reports did received response data
     
     - parameter messageData: received data
     - parameter count:       received data length
     */
    func communicatorDidRecivedData(messageData: NSData, count: Int)
    
    /**
     Communicator reports if connection state did changed
     
     - parameter connected: is connected or not
     */
    func communicatorDidChangedConnectionState(connected: Bool)
    
    /**
     Communicator reports if new SID was discovered
     
     - parameter newSid: the found SID object
     */
    func comminicatorDidDiscoveredSidId(newSid: SID)
    
    /**
     Communicator reports if there are SIDs longer as 5 seconds not reported
     
     - parameter oldSid: did lost SIDs as Array
     */
    func communicatorDidLostSidIds(oldSid: [SID])
}

/// Sid communicator
class SIDCommunicator: NSObject, DataTransferDelegate {
    
    /// The netto message size (MTU minus frame header information)
    var messageFrameSize: Int {
        return BLEComManager.mtuSize - 4
    }
    
    /// The Communicator delegate object
    var delegate: SIDCommunicatorDelegate?
    
    /// Sending data package
    var currentPackage: DataFramePackage?
    
    /// A set of discovered Sid IDs
    var currentFoundSidIds = Set<SID>()
    
    /// The receiveing package
    private var currentReceivingPackage: DataFramePackage?
    
    /**
     A object that must confirm to the DataTransfer protocol
     
     Normally the transporter is a BLEScanner object
     */
    var transporter: DataTransfer
    
    /// Current connected SID object
    var connectedSid: SID?
    
    /**
     Init point
     
     - returns: self as communicator object
     */
    required override init() {
        self.transporter = BLEScanner()
        super.init()
        self.transporter.delegate = self
    }
    
    /**
     Convenience init point with transporter
     
     - parameter transporter: transporter object
     - parameter delegate:    the communicator delegate object
     
     - returns: self as communicator object
     */
    convenience init(transporter: BLEScanner, delegate: SIDCommunicatorDelegate) {
        self.init()
        self.transporter = transporter
        self.delegate = delegate
    }
    
    /**
     Sendign data to connected SID
     
     - parameter sendData: the message data, that will be sent to SID
     
     - returns: if sending successful, if not the error description
     */
    func sendData(sendData: NSData) -> (success: Bool, error: String?) {
        if self.currentPackage != nil {
            return (false, "Sending in progress")
        } else {
            let data = sendData
            //print("----------------------------------------")
            //print("Send Encrypted Message: \(data.toHexString())")
            //print("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
            //let key = NSData.withBytes(self.cryptoManager.key)
            //print("With key: \(key.toHexString())")
            //print("-----------  sended message with id: \(message.id) -------------")
            
            self.currentPackage = DataFramePackage(messageData: data, frameSize: self.messageFrameSize)
            if let currentFrame = self.currentPackage?.currentFrame {
                self.sendFrame(currentFrame)
            } else {
                return (false, "DataFramePackage has no frames to send")
            }
            return (true, nil)
        }
    }
    
    /**
     Let transporter connect to SID-Peripheral with comming SID-ID
     
     - parameter sidId: sidId as String that transporter should connect to
     */
    func connectToSid(sidId: String) {
        self.transporter.delegate = self
        self.transporter.connectToSidWithId(sidId)
    }
    
    /**
     Reset sending package to nil
     */
    func resetCurrentPackage() {
        self.currentPackage = nil
    }
    
    /**
     Reset received package to nil
     */
    func resetReceivedPackage() {
        self.currentReceivingPackage = nil
    }
    
    /**
     Empty found sids list
     */
    func resetFoundSids() {
        self.currentFoundSidIds = Set<SID>()
    }
    
    /**
     Comming Dataframe will sent to SID peripheral
     
     - parameter frame: Dataframe that will be sent to SID
     */
    private func sendFrame(frame: DataFrame) {
        self.transporter.sendData(frame.data)
    }
    
    /**
     Checks if a SID ID is already discovered.
     
     - parameter sidId: A SID ID string
     
     - returns: When already in list it returns true, otherwise false.
     */
    func hasSidID(sidId: String) -> Bool {
        let savedSameSids = self.currentFoundSidIds.filter { (commingSid) -> Bool in
            let sidString = commingSid.sidID
            if sidString.lowercaseString == sidId.lowercaseString {
                return true
            } else {
                return false
            }
        }
        let didFoundSid = savedSameSids.count > 0
        //print ("did found connecting sidid: \(didFoundSid)")
        return didFoundSid
    }
    
    //MARK: - DataTransferDelegate
    /**
     Datatransger reports when message to SID did send
     
     - parameter dataTransferObject: the BLEScanner object as datatransfer
     - parameter data:               the sent message as NSData
     */
    func transferDidSendData(dataTransferObject: DataTransfer, data: NSData) {
        self.currentPackage?.currentIndex += 1
        if let currentFrame = self.currentPackage?.currentFrame {
            self.sendFrame(currentFrame)
        } else {
            if let _ = self.currentPackage?.message {
                self.resetCurrentPackage()
            }
        }
    }
    
    /**
     Datatransfer reports when new SID message was received
     
     - parameter dataTransferObject: the BLEScanner object as datatransfer
     - parameter data:               the received data as NSData
     */
    func transferDidReceivedData(dataTransferObject: DataTransfer, data: NSData) {
        if self.currentReceivingPackage == nil {
            self.currentReceivingPackage = DataFramePackage()
        }
        let frame = DataFrame(rawData: data)
        self.currentReceivingPackage?.frames.append(frame)
        
        if frame.type == .Single || frame.type == .Eop {
            if let messageData = self.currentReceivingPackage?.message {
                self.delegate?.communicatorDidRecivedData(messageData, count: data.length / 4)
            }  else {
                self.delegate?.communicatorDidRecivedData(NSData(), count: 0)
            }
        }
    }
    
    /**
     Datatransfer reports if connection status to SID did changed
     
     - parameter dataTransferObject: BLEScanner object as dataTransfer
     - parameter isConnected:        didConnected or not as Bool
     */
    func transferDidChangedConnectionState(dataTransferObject: DataTransfer, isConnected: Bool) {
        self.delegate?.communicatorDidChangedConnectionState(isConnected)
    }
    
    /**
     Datatransfer reports discovered SID object
     
     - parameter dataTransferObject: current used data transfer
     - parameter newSid:             discovered new SID object
     */
    func transferDidDiscoveredSidId(dataTransferObject: DataTransfer, newSid: SID) {
        let savedSameSids = self.currentFoundSidIds.filter { (commingSid) -> Bool in
            let sidString = commingSid.sidID
            if sidString == newSid.sidID {
                return true
            } else {
                return false
            }
        }
        let replaceOldSids = savedSameSids.count > 0
        if replaceOldSids == true {
            let oldSidArray = Array(savedSameSids)
            for oldSid in oldSidArray {
                self.currentFoundSidIds.remove(oldSid)
            }
        }
        var newcommingSid = newSid
        if newcommingSid.sidID == self.connectedSid?.sidID {
            newcommingSid.isConnected = (self.connectedSid?.isConnected)!
            newcommingSid.peripheral = (self.connectedSid?.peripheral)!
        }
        self.currentFoundSidIds.insert(newSid)
        if replaceOldSids == false {
            self.delegate?.comminicatorDidDiscoveredSidId(newSid)
        }
    }
    
    /**
     In transporter runs a timer, it reports wenn all saved SIDs must be filtered
     
     - parameter dataTransferObject: Scanner instance
     */
    func transferShouldFilterOldIds(dataTransferObject: DataTransfer) {
        self.filterOldSidIds()
    }
    /**
     Check all saved sids with discovery date (time), all older (discovered before 5 seconds)
     sids will be deleted from List. Scanner will be started after delete old sids and the deletion
     will be informed
     */
    func filterOldSidIds() {
        let lostSids = self.currentFoundSidIds.filter{ (sid) -> Bool in
            let time = sid.discoveryDate.timeIntervalSinceNow
            if time < -5.08 {
                if sid.sidID == self.connectedSid?.sidID {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        }
        if lostSids.count > 0 {
            let sidArray = Array(lostSids)
            for sid in lostSids {
                self.currentFoundSidIds.remove(sid)
            }
            self.delegate?.communicatorDidLostSidIds(sidArray.map({$0}))
        }
    }
    
    /**
     Transporter reports if that was successfully connected with a SID
     
     - parameter dataTransferObject: transporter instance
     - parameter sid:                connected SID instance
     */
    func transferDidconnectedSid(dataTransferObject: DataTransfer, sid: SID) {
        print ("sid: \(sid.sidID) did connected")
        self.connectedSid = sid
    }

}