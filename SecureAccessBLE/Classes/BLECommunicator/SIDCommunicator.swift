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
    func communicatorDidReceivedData(_ messageData: Data, count: Int)

    /**
     Communicator reports if a connection attempt succeeded

     - parameter communicator: The communicator object
     - parameter sid: The SID the connection is made to
     */
    func communicatorDidConnectSid(_ communicator: SIDCommunicator, sid: SID)

    /**
     Communicator reports if a connection attempt failed

     - parameter communicator: The communicator object
     - parameter sid: The SID the connection should have made to
     - parameter error: Describes the error
     */
    func communicatorDidFailToConnectSid(_ communicator: SIDCommunicator, sid: SID, error: Error?)

    /**
     Communicator reports if connection state did changed

     - parameter communicator: The communicator object
     - parameter state: The state of the transfer connection.
     */
    func communicatorDidChangedConnectionState(_ communicator: SIDCommunicator, state: TransferConnectionState)

    /**
     Communicator reports if new SID was discovered

     - parameter newSid: the found SID object
     */
    func comminicatorDidDiscoveredSidId(_ newSid: SID)

    /**
     Communicator reports if there are SIDs longer as 5 seconds not reported

     - parameter oldSid: did lost SIDs as Array
     */
    func communicatorDidLostSidIds(_ oldSid: [SID])
}

/// Sid communicator
class SIDCommunicator: NSObject, DataTransferDelegate {

    /// The netto message size (MTU minus frame header information)
    var messageFrameSize: Int {
        return BLEManager.mtuSize - 4
    }

    /// The Communicator delegate object
    var delegate: SIDCommunicatorDelegate?

    /// Sending data package
    var currentPackage: DataFramePackage?

    /// A set of discovered Sid IDs
    var currentFoundSidIds = Set<SID>()

    /// The receiveing package
    fileprivate var currentReceivingPackage: DataFramePackage?

    /**
     A object that must confirm to the DataTransfer protocol

     Normally the transporter is a BLEScanner object
     */
    private var transporter: DataTransfer

    /// Current connected SID object
    private var connectedSid: SID? {
        if case let .connected(sorc) = transporter.connectionState {
            return sorc
        }
        return nil
    }

    /// Timer to filter old SIDs
    fileprivate var filterTimer: Timer?

    /// The interval a timer is triggered to remove outdated discovered SORCs
    private let removeOutdatedSorcsTimerIntervalSeconds: Double = 2

    /// The duration a SORC is considered outdated if last discovery date is greater than this duration
    private let sorcOutdatedDurationSeconds: Double = 5

    /**
     Init point

     - returns: self as communicator object
     */
    init(transporter: DataTransfer) {
        self.transporter = transporter
        super.init()
        self.transporter.delegate = self
        filterTimer = Timer.scheduledTimer(timeInterval: removeOutdatedSorcsTimerIntervalSeconds,
                                           target: self,
                                           selector: #selector(filterOldSidIds),
                                           userInfo: nil,
                                           repeats: true)
    }

    /**
     Sendign data to connected SID

     - parameter sendData: the message data, that will be sent to SID

     - returns: if sending successful, if not the error description
     */
    func sendData(_ sendData: Data) -> (success: Bool, error: String?) {
        if currentPackage != nil {
            return (false, "Sending in progress")
        } else {
            let data = sendData
            // debugPrint("----------------------------------------")
            // debugPrint("Send Encrypted Message: \(data.toHexString())")
            // debugPrint("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
            // let key = NSData.withBytes(self.cryptoManager.key)
            // debugPrint("With key: \(key.toHexString())")
            // debugPrint("-----------  sended message with id: \(message.id) -------------")

            currentPackage = DataFramePackage(messageData: data, frameSize: messageFrameSize)
            if let currentFrame = self.currentPackage?.currentFrame {
                sendFrame(currentFrame)
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
    func connectToSorc(_ sidId: String) {
        let optSorc = currentFoundSidIds
            .filter({ $0.sidID.lowercased() == sidId.replacingOccurrences(of: "-", with: "").lowercased() })
            .first
        if let sorc = optSorc {
            transporter.connectToSorc(sorc)
        } else {
            print("SIDCommunicator can't connect to SORC that is not discovered.")
        }
    }

    /**
     Reset sending package to nil
     */
    func resetCurrentPackage() {
        currentPackage = nil
    }

    /**
     Reset received package to nil
     */
    func resetReceivedPackage() {
        currentReceivingPackage = nil
    }

    /**
     Empty found sids list
     */
    func resetFoundSids() {
        currentFoundSidIds = Set<SID>()
    }

    /**
     Comming Dataframe will sent to SID peripheral

     - parameter frame: Dataframe that will be sent to SID
     */
    fileprivate func sendFrame(_ frame: DataFrame) {
        transporter.sendData(frame.data)
    }

    /**
     Checks if a SID ID is already discovered.

     - parameter sidId: A SID ID string

     - returns: When already in list it returns true, otherwise false.
     */
    func hasSidID(_ sidId: String) -> Bool {
        let savedSameSids = currentFoundSidIds.filter { (commingSid) -> Bool in
            let sidString = commingSid.sidID
            if sidString.lowercased() == sidId.lowercased() {
                return true
            } else {
                return false
            }
        }
        let didFoundSid = savedSameSids.count > 0
        // print ("did found connecting sidid: \(didFoundSid)")
        return didFoundSid
    }

    // MARK: - DataTransferDelegate
    /**
     Datatransger reports when message to SID did send

     - parameter dataTransferObject: the BLEScanner object as datatransfer
     - parameter data:               the sent message as NSData
     */
    func transferDidSendData(_: DataTransfer, data _: Data) {
        currentPackage?.currentIndex += 1
        if let currentFrame = self.currentPackage?.currentFrame {
            sendFrame(currentFrame)
        } else {
            if let _ = self.currentPackage?.message {
                resetCurrentPackage()
            }
        }
    }

    /**
     Datatransfer reports when new SID message was received

     - parameter dataTransferObject: the BLEScanner object as datatransfer
     - parameter data:               the received data as NSData
     */
    func transferDidReceivedData(_: DataTransfer, data: Data) {
        if currentReceivingPackage == nil {
            currentReceivingPackage = DataFramePackage()
        }
        let frame = DataFrame(rawData: data)
        currentReceivingPackage?.frames.append(frame)

        if frame.type == .single || frame.type == .eop {
            if let messageData = self.currentReceivingPackage?.message {
                delegate?.communicatorDidReceivedData(messageData as Data, count: data.count / 4)
            } else {
                delegate?.communicatorDidReceivedData(Data(), count: 0)
            }
        }
    }

    func transferDidChangedConnectionState(_: DataTransfer, state: TransferConnectionState) {
        if let sorcID = connectedSid?.sidID {
            currentFoundSidIds = Set(currentFoundSidIds.filter { $0.sidID != sorcID })
        }
        delegate?.communicatorDidChangedConnectionState(self, state: state)
    }

    /**
     Datatransfer reports discovered SID object

     - parameter dataTransferObject: current used data transfer
     - parameter newSid:             discovered new SID object
     */
    func transferDidDiscoveredSidId(_: DataTransfer, newSid: SID) {
        let savedSameSids = currentFoundSidIds.filter { commingSid in
            return commingSid.sidID == newSid.sidID
        }
        let replaceOldSids = savedSameSids.count > 0
        if replaceOldSids {
            let oldSidArray = Array(savedSameSids)
            for oldSid in oldSidArray {
                currentFoundSidIds.remove(oldSid)
            }
        }
        var newcommingSid = newSid
        if newcommingSid.sidID == connectedSid?.sidID {
            newcommingSid.isConnected = (connectedSid?.isConnected)!
            newcommingSid.peripheral = (connectedSid?.peripheral)!
        }
        currentFoundSidIds.insert(newSid)
        if !replaceOldSids {
            delegate?.comminicatorDidDiscoveredSidId(newSid)
        }
    }

    /**
     Check all saved sids with discovery date (time), all older (discovered before 5 seconds)
     sids will be deleted from List. Scanner will be started after delete old sids and the deletion
     will be informed
     */
    func filterOldSidIds() {
        let lostSids = currentFoundSidIds.filter { (sid) -> Bool in
            let outdated = sid.discoveryDate.timeIntervalSinceNow < -sorcOutdatedDurationSeconds
            if outdated {
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
                currentFoundSidIds.remove(sid)
            }
            delegate?.communicatorDidLostSidIds(sidArray.map({ $0 }))
        }
    }

    /**
     Transporter reports if that was successfully connected with a SID

     - parameter dataTransferObject: transporter instance
     - parameter sid:                connected SID instance
     */
    func transferDidConnectSid(_: DataTransfer, sid: SID) {
        delegate?.communicatorDidConnectSid(self, sid: sid)
    }

    /**
     Tells the delegate if a connection attempt failed

     - parameter dataTransferObject: Transporter instance
     - parameter sid: The SID the connection should have made to
     - parameter error: Describes the error
     */
    func transferDidFailToConnectSid(_: DataTransfer, sid: SID, error: Error?) {
        // TODO: check if something has to be cleaned up in this instance
        delegate?.communicatorDidFailToConnectSid(self, sid: sid, error: error)
    }
}
