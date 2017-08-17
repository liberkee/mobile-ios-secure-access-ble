//
//  SorcDataCommunicator.swift
//  SecureAccessBLE
//
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import Foundation
import CommonUtils

/// Sends and receives data by sending separate frames based on the current MTU size.
class SorcDataCommunicator {

    let dataReceived = PublishSubject<Data>()

    /// Updating the MTU size only takes effect on the next data package sent, not the current one.
    var mtuSize = 20

    /// The netto message size (MTU minus frame header information)
    private var messageFrameSize: Int {
        return mtuSize - 4
    }

    var isBusy: Bool {
        return currentPackage != nil
    }

    /// Sending data package
    private var currentPackage: DataFramePackage?

    /// The receiveing package
    private var currentReceivingPackage: DataFramePackage?

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

        transporter.sentData.subscribeNext { [weak self] error in
            if let error = error {
                // TODO: PLAM-1374 handle error
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
                // TODO: PLAM-1374 handle error
                break
            }
        }
        .disposed(by: disposeBag)
    }

    /**
     Sending data to connected SORC

     - parameter sendData: the message data, that will be sent to SORC

     - returns: if sending successful, if not the error description
     */
    func sendData(_ data: Data) -> (success: Bool, error: String?) {
        if currentPackage != nil {
            return (false, "Sending in progress")
        } else {
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

    func resetCurrentPackage() {
        currentPackage = nil
    }

    private func resetReceivedPackage() {
        currentReceivingPackage = nil
    }

    // MARK: Private methods

    fileprivate func sendFrame(_ frame: DataFrame) {
        transporter.sendData(frame.data)
    }

    private func handleSentData() {
        currentPackage?.currentIndex += 1
        if let currentFrame = self.currentPackage?.currentFrame {
            sendFrame(currentFrame)
        } else {
            if currentPackage?.message != nil {
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
                dataReceived.onNext(messageData)
            }
            resetReceivedPackage()
        }
    }
}
