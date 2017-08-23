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

    let connectionChange = ChangeSubject<TransportConnectionChange>(state: .disconnected)
    let dataReceived = PublishSubject<Data>()

    /// Updating the MTU size only takes effect on the next data package sent, not the current one.
    private var mtuSize = 20

    /// The netto message size (MTU minus frame header information)
    private var messageFrameSize: Int {
        return mtuSize - 4
    }

    /// TODO: PLAM-959 Communicate back if a package was sent so that queuing becomes possible?
    var isBusy: Bool {
        return currentPackage != nil
    }

    /// Sending data package
    private var currentPackage: DataFramePackage?

    /// The receiveing package
    private var currentReceivingPackage: DataFramePackage?

    private let sorcConnectionManager: SorcConnectionManager

    private let disposeBag = DisposeBag()

    /**
     Init point

     - returns: self as communicator object
     */
    init(sorcConnectionManager: SorcConnectionManager) {
        self.sorcConnectionManager = sorcConnectionManager

        sorcConnectionManager.connectionChange.subscribeNext { [weak self] change in
            self?.handleDataConnectionChange(change)
        }
        .disposed(by: disposeBag)

        sorcConnectionManager.sentData.subscribeNext { [weak self] error in
            if let error = error {
                // TODO: PLAM-1374 handle error
            } else {
                self?.handleSentData()
            }
        }
        .disposed(by: disposeBag)

        sorcConnectionManager.receivedData.subscribeNext { [weak self] result in
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

    func connectToSorc(_ sorcID: SorcID) {
        guard connectionChange.state == .disconnected
            || connectionChange.state == .connecting(sorcID: sorcID, state: .physical) else { return }

        if connectionChange.state == .disconnected {
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .physical),
                                          action: .connect(sorcID: sorcID)))
        }

        sorcConnectionManager.connectToSorc(sorcID)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    /**
     Sending data to connected SORC

     - parameter sendData: the message data, that will be sent to SORC

     - returns: if sending successful, if not the error description
     */
    func sendData(_ data: Data) -> (success: Bool, error: String?) {
        // TODO: PLAM-959 add preconditions

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

    private func resetCurrentPackage() {
        currentPackage = nil
    }

    private func resetReceivedPackage() {
        currentReceivingPackage = nil
    }

    // MARK: Private methods

    private func disconnect(withAction action: TransportConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        reset()
        connectionChange.onNext(.init(state: .disconnected, action: action))
        sorcConnectionManager.disconnect()
    }

    private func reset() {
        resetCurrentPackage()
    }

    private func handleDataConnectionChange(_ change: DataConnectionChange) {
        switch change.state {
        case .connecting: break
        case let .connected(dataSorcID):
            guard case let .connecting(sorcID, .physical) = connectionChange.state, sorcID == dataSorcID else { return }
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .requestingMTU),
                                          action: .physicalConnectionEstablished(sorcID: sorcID)))
            sendMTURequest()
        case .disconnected:
            if connectionChange.state == .disconnected { return }
            reset()
            switch change.action {
            case let .connectingFailed(sorcID):
                connectionChange.onNext(.init(state: .disconnected,
                                              action: .connectingFailed(sorcID: sorcID,
                                                                        error: .physicalConnectingFailed)))
            case .disconnect:
                connectionChange.onNext(.init(state: .disconnected, action: .disconnect))
            case .disconnected:
                connectionChange.onNext(.init(state: .disconnected,
                                              action: .connectionLost(error: .physicalConnectionLost)))
            default: break
            }
        }
    }

    private func sendFrame(_ frame: DataFrame) {
        sorcConnectionManager.sendData(frame.data)
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

                /// TODO: PLAM-959 Check if empty data causes issues
                let message = SorcMessage(rawData: messageData)
                if case .mtuReceive = message.id, let mtuSize = MTUSize(rawData: message.message).mtuSize {
                    handleMTUReceived(mtuSize: mtuSize)
                } else {
                    dataReceived.onNext(messageData)
                }
            }
            resetReceivedPackage()
        }
    }

    private func sendMTURequest() {
        let message = SorcMessage(id: SorcMessageID.mtuRequest, payload: MTUSize())
        sendData(message.data)
    }

    private func handleMTUReceived(mtuSize: Int) {
        guard case let .connecting(sorcID, connectingState) = connectionChange.state,
            connectingState == .requestingMTU else { return }

        self.mtuSize = mtuSize
        connectionChange.onNext(.init(state: .connected(sorcID: sorcID),
                                      action: .connectionEstablished(sorcID: sorcID)))
    }
}
