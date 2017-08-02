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
class SIDCommunicator: NSObject {

    /// The netto message size (MTU minus frame header information)
    var messageFrameSize: Int {
        return BLEManager.mtuSize - 4
    }

    /// The Communicator delegate object
    var delegate: SIDCommunicatorDelegate?

    /// Sending data package
    var currentPackage: DataFramePackage?

    /// The receiveing package
    fileprivate var currentReceivingPackage: DataFramePackage?

    /**
     A object that must confirm to the DataTransfer protocol

     Normally the transporter is a BLEScanner object
     */
    private var transporter: DataTransfer

    /**
     Init point

     - returns: self as communicator object
     */
    init(transporter: DataTransfer) {
        self.transporter = transporter
        super.init()
        self.transporter.delegate = self
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

    // MARK: Private methods

    /**
     Comming Dataframe will sent to SID peripheral

     - parameter frame: Dataframe that will be sent to SID
     */
    fileprivate func sendFrame(_ frame: DataFrame) {
        transporter.sendData(frame.data)
    }
}

// MARK: - DataTransferDelegate

extension SIDCommunicator: DataTransferDelegate {

    func transferDidDiscoveredSidId(_: DataTransfer, newSid: SID) {
        delegate?.comminicatorDidDiscoveredSidId(newSid)
    }

    func transferDidLostSidIds(_: DataTransfer, oldSids: [SID]) {
        delegate?.communicatorDidLostSidIds(oldSids)
    }

    func transferDidChangedConnectionState(_: DataTransfer, state: TransferConnectionState) {
        delegate?.communicatorDidChangedConnectionState(self, state: state)
    }

    func transferDidConnectSid(_: DataTransfer, sid: SID) {
        delegate?.communicatorDidConnectSid(self, sid: sid)
    }

    func transferDidFailToConnectSid(_: DataTransfer, sid: SID, error: Error?) {
        delegate?.communicatorDidFailToConnectSid(self, sid: sid, error: error)
    }

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
}
