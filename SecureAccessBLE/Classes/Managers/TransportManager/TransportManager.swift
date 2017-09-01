//
//  TransportManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// Sends and receives data by sending separate frames based on the current MTU size.
class TransportManager: TransportManagerType {

    let connectionChange = ChangeSubject<TransportConnectionChange>(state: .disconnected)

    let dataSent = PublishSubject<Result<Data>>()
    let dataReceived = PublishSubject<Result<Data>>()

    private let defaultMTUSize = 20

    /// Updating the MTU size only takes effect on the next data package sent, not the current one.
    private var mtuSize: Int

    /// The netto message size (MTU minus frame header information)
    private var messageFrameSize: Int {
        return mtuSize - 4
    }

    private var sendingPackage: DataFramePackage?
    private var receivingPackage: DataFramePackage?

    private let connectionManager: ConnectionManagerType
    private let disposeBag = DisposeBag()

    private var actionLeadingToDisconnect: TransportConnectionChange.Action?

    init(connectionManager: ConnectionManagerType) {
        mtuSize = defaultMTUSize

        self.connectionManager = connectionManager

        connectionManager.connectionChange.subscribeNext { [weak self] change in
            self?.handlePhysicalConnectionChange(change)
        }
        .disposed(by: disposeBag)

        connectionManager.dataSent.subscribeNext { [weak self] error in
            self?.handleSentData(error: error)
        }
        .disposed(by: disposeBag)

        connectionManager.dataReceived.subscribeNext { [weak self] result in
            self?.handleReceivedDataResult(result)
        }
        .disposed(by: disposeBag)
    }

    func connectToSorc(_ sorcID: SorcID) {
        guard connectionChange.state == .disconnected
            || connectionChange.state == .connecting(sorcID: sorcID, state: .physical) else { return }

        if connectionChange.state == .disconnected {
            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID, state: .physical),
                action: .connect(sorcID: sorcID)
            ))
        }

        connectionManager.connectToSorc(sorcID)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    func sendData(_ data: Data) {
        // TODO: PLAM-959 add preconditions
        // TODO: PLAM-959 add queuing

        print("BLA: try sending data: \(data.toHexString())")

        if sendingPackage != nil || receivingPackage != nil {
            print("BLA Sending/Receiving in progress")
        } else {
            // debugPrint("----------------------------------------")
            // debugPrint("Send Encrypted Message: \(data.toHexString())")
            // debugPrint("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
            // let key = NSData.withBytes(self.cryptoManager.key)
            // debugPrint("With key: \(key.toHexString())")
            // debugPrint("-----------  sended message with id: \(message.id) -------------")

            sendingPackage = DataFramePackage(messageData: data, frameSize: messageFrameSize)
            if let currentFrame = self.sendingPackage?.currentFrame {
                sendFrame(currentFrame)
            } else {
                print("DataFramePackage has no frames to send")
            }
        }
    }

    // MARK: - Private methods -

    private func resetCurrentPackage() {
        print("BLA resetCurrentPackage")
        sendingPackage = nil
    }

    private func resetReceivedPackage() {
        print("BLA resetReceivedPackage")
        receivingPackage = nil
    }

    // MARK: Private methods

    private func disconnect(withAction action: TransportConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        actionLeadingToDisconnect = action
        connectionManager.disconnect()
    }

    private func reset() {
        resetCurrentPackage()
        resetReceivedPackage()
        mtuSize = defaultMTUSize
        actionLeadingToDisconnect = nil
    }

    private func handlePhysicalConnectionChange(_ change: PhysicalConnectionChange) {
        switch change.state {

        case .connecting: break
        case let .connected(dataSorcID):
            guard case let .connecting(sorcID, .physical) = connectionChange.state,
                sorcID == dataSorcID else { return }

            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID, state: .requestingMTU),
                action: .physicalConnectionEstablished(sorcID: sorcID)
            ))
            sendMTURequest()

        case .disconnected:
            if connectionChange.state == .disconnected { return }

            let actionLeadingToDisconnect = self.actionLeadingToDisconnect
            reset()
            if let action = actionLeadingToDisconnect {
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: action
                ))
                return
            }

            switch change.action {
            case let .connectingFailed(sorcID):
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: .connectingFailed(sorcID: sorcID, error: .physicalConnectingFailed)
                ))
            case .disconnect:
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: .disconnect
                ))
            case .connectionLost:
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: .connectionLost(error: .physicalConnectionLost)
                ))
            default: break
            }
        }
    }

    private func sendFrame(_ frame: DataFrame) {
        connectionManager.sendData(frame.data)
    }

    private func handleSentData(error: Error?) {
        // TODO: PLAM-1374 handle error

        if let error = error {
            resetCurrentPackage()
            dataSent.onNext(.failure(error))
            return
        }

        guard let sendingPackage = sendingPackage else { return }
        sendingPackage.currentIndex += 1
        if let currentFrame = sendingPackage.currentFrame {
            sendFrame(currentFrame)
        } else {
            dataSent.onNext(.success(sendingPackage.message))
            resetCurrentPackage()
        }
    }

    private func handleReceivedDataResult(_ result: Result<Data>) {
        switch connectionChange.state {
        case .connecting(_, .requestingMTU):
            break
        case .connected:
            break
        default:
            return
        }

        switch result {
        case let .success(data):
            handleReceivedData(data)
        case let .failure(error):
            handleReceivedDataError(error)
        }
    }

    private func handleReceivedData(_ data: Data) {
        print("BLA handleReceivedData: \(data.toHexString())")

        if receivingPackage == nil {
            receivingPackage = DataFramePackage()
        }
        let frame = DataFrame(rawData: data)
        receivingPackage?.frames.append(frame)

        guard frame.type == .single || frame.type == .eop,
            let package = self.receivingPackage else { return }

        resetReceivedPackage()
        let messageData = package.message

        print("BLA handleReceivedMessageData: \(messageData.toHexString())")

        if case let .connecting(sorcID, .requestingMTU) = connectionChange.state {
            let message = SorcMessage(rawData: messageData)
            if message.id == .mtuReceive, let mtuSize = MTUSize(rawData: message.message).mtuSize {
                print("BLA mtuReceive: \(message.data.toHexString())")
                handleMTUReceived(mtuSize: mtuSize)
            } else {
                disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .invalidMTUResponse))
            }
        } else {
            dataReceived.onNext(.success(messageData))
        }
    }

    private func handleReceivedDataError(_ error: Error) {
        // TODO: PLAM-1374 handle error
        print("BLA handleReceivedData error")

        if case let .connecting(sorcID, .requestingMTU) = connectionChange.state {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .invalidMTUResponse))
        } else {
            dataReceived.onNext(.failure(error))
        }
    }

    private func sendMTURequest() {
        print("BLA sendMTURequest")
        let message = SorcMessage(id: SorcMessageID.mtuRequest, payload: MTUSize())
        sendData(message.data)
    }

    private func handleMTUReceived(mtuSize: Int) {
        print("BLA handleMTUReceived")
        guard case let .connecting(sorcID, .requestingMTU) = connectionChange.state else { return }

        self.mtuSize = mtuSize
        connectionChange.onNext(.init(
            state: .connected(sorcID: sorcID),
            action: .connectionEstablished(sorcID: sorcID)
        ))
    }
}
