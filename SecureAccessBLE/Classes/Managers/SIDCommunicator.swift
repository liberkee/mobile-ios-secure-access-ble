//
//  SIDCommunicator.swift
//  BLE
//
//  Created by Ke Song on 24.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation
import CommonUtils

/**
 *  SIDCommnicator takes a communication to SID and handles the response from SID.
 *  Sending and receiving message through data transfer
 */
protocol SIDCommunicatorDelegate {
    /**
     Communicator reports did received response data

     - parameter messageData: received data
     - parameter count:       received data length
     */
    func communicatorDidReceivedData(_ messageData: Data, count: Int)
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

     Normally the transporter is a SorcConnectionManager object
     */
    private let transporter: DataTransfer

    private let disposeBag = DisposeBag()

    /**
     Init point

     - returns: self as communicator object
     */
    init(transporter: DataTransfer) {
        self.transporter = transporter
        super.init()

        transporter.sentData.subscribeNext { [weak self] error in
            if let error = error {
                // TODO: handle error
            } else {
                self?.handleSentData()
            }
        }
        .disposed(by: disposeBag)

        transporter.receivedData.subscribeNext { [weak self] result in
            switch result {
            case let .success(data):
                self?.handleReceivedData(data)
            case let .error(error):
                // TODO: handle error
                break
            }
        }
        .disposed(by: disposeBag)
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

    private func handleSentData() {
        currentPackage?.currentIndex += 1
        if let currentFrame = self.currentPackage?.currentFrame {
            sendFrame(currentFrame)
        } else {
            if let _ = self.currentPackage?.message {
                resetCurrentPackage()
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
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
