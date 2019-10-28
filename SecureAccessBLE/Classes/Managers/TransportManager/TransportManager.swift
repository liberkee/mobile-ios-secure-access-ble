//
//  TransportManager.swift
//  SecureAccessBLE
//
//  Created on 23.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

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

    /// Used to know what action we need to send out after disconnect on lower layers happened
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
            || connectionChange.state == .connecting(sorcID: sorcID) else { return }

        if connectionChange.state == .disconnected {
            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID),
                action: .connect(sorcID: sorcID)
            ))
        }

        connectionManager.connectToSorc(sorcID)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    func sendData(_ data: Data) {
        guard case .connected = connectionChange.state else { return }
        sendDataInternal(data)
    }

    // MARK: - Private methods -

    private func reset() {
        resetSendingPackage()
        resetReceivingPackage()
        mtuSize = defaultMTUSize
        actionLeadingToDisconnect = nil
    }

    // MARK: - Connecting handling

    private func disconnect(withAction action: TransportConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        actionLeadingToDisconnect = action
        connectionManager.disconnect()
    }

    private func handlePhysicalConnectionChange(_ change: PhysicalConnectionChange) {
        switch change.state {
        case .connecting: break
        case let .connected(dataSorcID):
            guard case let .connecting(sorcID) = connectionChange.state,
                sorcID == dataSorcID else { return }

            guard case let .connectionEstablished(sorcID: _, mtuSize: mtuSize) = change.action else {
                return
            }
            self.mtuSize = mtuSize

            connectionChange.onNext(.init(
                state: .connected(sorcID: sorcID),
                action: .connectionEstablished(sorcID: sorcID)
            ))

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

    // MARK: - Data package and frame handling

    private func sendDataInternal(_ data: Data) {
        if sendingPackage != nil || receivingPackage != nil {
            HSMLog(message: "BLE - Sending/Receiving in progress", level: .debug)
        } else {
            sendingPackage = DataFramePackage(messageData: data, frameSize: messageFrameSize)
            if let currentFrame = self.sendingPackage?.currentFrame {
                sendFrame(currentFrame)
            } else {
                HSMLog(message: "BLE - Data frame package has no frames to send", level: .error)
            }
        }
    }

    private func sendFrame(_ frame: DataFrame) {
        connectionManager.sendData(frame.data)
    }

    private func handleSentData(error: Error?) {
        if let error = error {
            resetSendingPackage()
            dataSent.onNext(.failure(error))
            return
        }

        guard let sendingPackage = sendingPackage else { return }
        sendingPackage.currentIndex += 1
        if let currentFrame = sendingPackage.currentFrame {
            sendFrame(currentFrame)
        } else {
            resetSendingPackage()
            dataSent.onNext(.success(sendingPackage.message))
        }
    }

    private func handleReceivedDataResult(_ result: Result<Data>) {
        guard case .connected = connectionChange.state else { return }
        switch result {
        case let .success(data):
            handleReceivedData(data)
        case let .failure(error):
            handleReceivedDataError(error)
        }
    }

    private func handleReceivedData(_ data: Data) {
        if receivingPackage == nil {
            receivingPackage = DataFramePackage()
        }
        let frame = DataFrame(rawData: data)
        receivingPackage?.frames.append(frame)

        guard frame.type == .single || frame.type == .eop,
            let package = self.receivingPackage else { return }

        resetReceivingPackage()
        let messageData = package.message

        dataReceived.onNext(.success(messageData))
    }

    private func handleReceivedDataError(_ error: Error) {
        dataReceived.onNext(.failure(error))
    }

    private func resetSendingPackage() {
        sendingPackage = nil
    }

    private func resetReceivingPackage() {
        receivingPackage = nil
    }
}
