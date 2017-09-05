//
//  SecurityManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Sends/encrypts and receives/decrypts SORC messages.
class SecurityManager: SecurityManagerType {

    enum Error: Swift.Error {
        case decryptionFailed
    }

    let connectionChange = ChangeSubject<SecureConnectionChange>(state: .disconnected)

    let messageSent = PublishSubject<Result<SorcMessage>>()
    let messageReceived = PublishSubject<Result<SorcMessage>>()

    private var challenger: ChallengeService?

    private var leaseID: String = ""
    private var leaseTokenID: String = ""
    private var sorcAccessKey: String = ""
    fileprivate var sorcID: SorcID = ""
    private var blobData: String? = ""
    fileprivate var blobCounter: Int = 0

    private let transportManager: TransportManagerType
    private var cryptoManager: CryptoManager = ZeroSecurityManager()
    private let disposeBag = DisposeBag()

    /// Used to know what action we need to send out after disconnect on lower layers happened
    private var actionLeadingToDisconnect: SecureConnectionChange.Action?

    init(transportManager: TransportManagerType) {
        self.transportManager = transportManager

        transportManager.connectionChange.subscribeNext { [weak self] change in
            self?.handleTransportConnectionChange(change)
        }
        .disposed(by: disposeBag)

        transportManager.dataSent.subscribeNext { [weak self] result in
            self?.handleDataSent(result: result)
        }
        .disposed(by: disposeBag)

        transportManager.dataReceived.subscribeNext { [weak self] result in
            self?.handleDataReceived(result: result)
        }
        .disposed(by: disposeBag)
    }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        guard connectionChange.state == .disconnected
            || connectionChange.state == .connecting(sorcID: leaseToken.sorcID, state: .physical)
        else { return }

        sorcID = leaseToken.sorcID
        leaseTokenID = leaseToken.id
        leaseID = leaseToken.leaseID
        sorcAccessKey = leaseToken.sorcAccessKey
        blobData = leaseTokenBlob.data
        blobCounter = leaseTokenBlob.messageCounter

        if connectionChange.state == .disconnected {
            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID, state: .physical),
                action: .connect(sorcID: sorcID)
            ))
        }

        transportManager.connectToSorc(sorcID)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    func sendMessage(_ message: SorcMessage) {
        guard case .connected = connectionChange.state else { return }
        sendMessageInternal(message)
    }

    // MARK: - Private methods -

    private func reset() {
        actionLeadingToDisconnect = nil
        cryptoManager = ZeroSecurityManager()
    }

    // MARK: - Connection handling

    fileprivate func disconnect(withAction action: SecureConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        actionLeadingToDisconnect = action
        transportManager.disconnect()
    }

    private func handleTransportConnectionChange(_ transportChange: TransportConnectionChange) {

        switch transportChange.state {
        case let .connecting(transportSorcID, transportConnectingState):
            switch transportConnectingState {
            case .physical: break
            case .requestingMTU:
                guard case let .connecting(sorcID, .physical) = connectionChange.state, sorcID == transportSorcID else {
                    return
                }
                connectionChange.onNext(.init(
                    state: .connecting(sorcID: sorcID, state: .transport),
                    action: .physicalConnectionEstablished(sorcID: sorcID)
                ))
            }
        case let .connected(sorcID):
            guard connectionChange.state == .connecting(sorcID: sorcID, state: .transport) else { return }
            establishCrypto()
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
            switch transportChange.action {
            case let .connectingFailed(sorcID, transportError):
                let error = SecureConnectionChange.ConnectingFailedError(transportConnectingFailedError: transportError)
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: .connectingFailed(sorcID: sorcID, error: error)
                ))
            case .disconnect:
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: .disconnect
                ))
            case let .connectionLost(transportError):
                let error = SecureConnectionChange.ConnectionLostError(transportConnectionLostError: transportError)
                connectionChange.onNext(.init(
                    state: .disconnected,
                    action: .connectionLost(error: error)
                ))
            default: break
            }
        }
    }

    // MARK: - Challenging

    private func establishCrypto() {
        if sorcID.isEmpty || sorcAccessKey.isEmpty {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }
        challenger = ChallengeService(leaseID: leaseID, sorcID: sorcID, leaseTokenID: leaseTokenID, sorcAccessKey: sorcAccessKey)
        challenger?.delegate = self
        if challenger == nil {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }
        do {
            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID, state: .challenging),
                action: .transportConnectionEstablished(sorcID: sorcID)
            ))
            try challenger?.beginChallenge()
        } catch {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    fileprivate func sendBlob() {
        if blobData?.isEmpty == false {
            if let payload = LTBlobPayload(blobData: blobData!) {
                let message = SorcMessage(id: .ltBlob, payload: payload)
                sendMessageInternal(message)
            } else {
                print("BLA Blob data error")
                disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            }
        } else {
            print("BLA Blob data error")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    fileprivate func enableEncryption(withSessionKey key: [UInt8]) {
        cryptoManager = AesCbcCryptoManager(key: key)
    }

    // MARK: - Message handling

    fileprivate func sendMessageInternal(_ message: SorcMessage) {
        let data = cryptoManager.encryptMessage(message)
        transportManager.sendData(data)
    }

    private func handleDataSent(result: Result<Data>) {
        switch connectionChange.state {
        case .connecting(_, .challenging):
            handleDataSentWhileChallenging(result: result)
        case .connected:
            handleDataSentWhileConnected(result: result)
        default:
            return
        }
    }

    private func handleDataSentWhileChallenging(result: Result<Data>) {
        if case .failure = result {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    private func handleDataSentWhileConnected(result: Result<Data>) {
        if case let .failure(error) = result {
            messageReceived.onNext(.failure(error))
        }
    }

    private func handleDataReceived(result: Result<Data>) {
        switch connectionChange.state {
        case .connecting(_, .challenging):
            handleDataReceivedWhileChallenging(result: result)
        case .connected:
            handleDataReceivedWhileConnected(result: result)
        default:
            return
        }
    }

    private func handleDataReceivedWhileChallenging(result: Result<Data>) {
        guard case let .success(data) = result else {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }

        let message = SorcMessage(rawData: data)
        switch message.id {
        case .challengeSorcResponse, .badChallengeSorcResponse, .ltAck:
            do {
                try challenger?.handleReceivedChallengerMessage(message)
            } catch {
                disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            }
        case .ltBlobRequest:
            let payload = BlobRequest(rawData: message.message)
            if blobCounter > payload.blobMessageID {
                sendBlob()
            }
        default: break
        }
    }

    private func handleDataReceivedWhileConnected(result: Result<Data>) {
        switch result {
        case let .success(data):
            let message = cryptoManager.decryptData(data)
            let messageResult: Result<SorcMessage> = message.id != SorcMessageID.notValid ?
                .success(message) : .failure(Error.decryptionFailed)
            messageReceived.onNext(messageResult)
        case let .failure(error):
            messageReceived.onNext(.failure(error))
        }
    }
}

// MARK: - ChallengeServiceDelegate

extension SecurityManager: ChallengeServiceDelegate {

    func challengerWantsSendMessage(_ message: SorcMessage) {
        sendMessageInternal(message)
    }

    func challengerFinishedWithSessionKey(_ key: [UInt8]) {
        enableEncryption(withSessionKey: key)
        connectionChange.onNext(.init(
            state: .connected(sorcID: sorcID),
            action: .connectionEstablished(sorcID: sorcID))
        )
    }

    func challengerAbort(_: ChallengeError) {
        disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
    }

    func challengerNeedsSendBlob(latestBlobCounter: Int?) {

        guard latestBlobCounter == nil || blobCounter >= latestBlobCounter! else {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .blobOutdated))
            return
        }
        sendBlob()
    }
}

// MARK: - Error extensions

private extension SecureConnectionChange.ConnectingFailedError {

    init(transportConnectingFailedError: TransportConnectionChange.ConnectingFailedError) {
        switch transportConnectingFailedError {
        case .physicalConnectingFailed:
            self = .physicalConnectingFailed
        case .invalidMTUResponse:
            self = .invalidMTUResponse
        }
    }
}

private extension SecureConnectionChange.ConnectionLostError {

    init(transportConnectionLostError: TransportConnectionChange.ConnectionLostError) {
        switch transportConnectionLostError {
        case .physicalConnectionLost:
            self = .physicalConnectionLost
        }
    }
}
