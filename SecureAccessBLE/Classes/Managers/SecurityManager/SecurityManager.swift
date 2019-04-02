//
//  SecurityManager.swift
//  SecureAccessBLE
//
//  Created on 18.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Sends/encrypts and receives/decrypts SORC messages.
class SecurityManager: SecurityManagerType {
    enum Error: Swift.Error {
        case decryptionFailed
    }

    let connectionChange = ChangeSubject<SecureConnectionChange>(state: .disconnected)

    // TODO: There is nowhere an onNext call on this subject, although some logic in SessionManager rely on this (but is never executed)
    let messageSent = PublishSubject<Result<SorcMessage>>()
    let messageReceived = PublishSubject<Result<SorcMessage>>()

    private var challenger: Challenger?

    private var leaseToken: LeaseToken?
    fileprivate var leaseTokenBlob: LeaseTokenBlob?

    fileprivate var sorcID: SorcID? {
        return leaseToken?.sorcID
    }

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

        self.leaseToken = leaseToken
        self.leaseTokenBlob = leaseTokenBlob
        let sorcID = leaseToken.sorcID

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
        guard let leaseToken = leaseToken else { return }
        let sorcID = leaseToken.sorcID
        guard let challenger = Challenger(leaseToken: leaseToken) else {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }
        self.challenger = challenger
        challenger.delegate = self
        do {
            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID, state: .challenging),
                action: .transportConnectionEstablished(sorcID: sorcID)
            ))
            try challenger.beginChallenge()
        } catch {
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    fileprivate func sendBlob() {
        guard let sorcID = self.sorcID, let blobData = leaseTokenBlob?.data else { return }
        if let payload = LTBlobPayload(blobData: blobData) {
            let message = SorcMessage(id: .ltBlob, payload: payload)
            sendMessageInternal(message)
        } else {
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
        guard let sorcID = self.sorcID else { return }
        switch result {
        case .failure:
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        case let .success(data):
            challenger?.handleSentChallengerMessage(SorcMessage(rawData: data))
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
        guard let sorcID = self.sorcID else { return }
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
            guard let messageCounter = leaseTokenBlob?.messageCounter,
                let blobRequestPayload = try? BlobRequest(rawData: message.message) else { return }
            let blobRequestCounter = blobRequestPayload.blobMessageCounter
            handleBlobRequestDependingOnCounter(counterFromSorc: blobRequestCounter, localCounter: messageCounter, sorcId: sorcID)
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

    private func handleBlobRequestDependingOnCounter(counterFromSorc: Int, localCounter: Int, sorcId: SorcID) {
        if localCounter > counterFromSorc {
            sendBlob()
        } else if localCounter == counterFromSorc {
            disconnect(withAction: .connectingFailed(sorcID: sorcId, error: .invalidTimeFrame))
        } else {
            disconnect(withAction: .connectingFailed(sorcID: sorcId, error: .blobOutdated))
        }
    }
}

// MARK: - ChallengerDelegate

extension SecurityManager: ChallengerDelegate {
    func challengerWantsSendMessage(_ message: SorcMessage) {
        sendMessageInternal(message)
    }

    func challengerFinishedWithSessionKey(_ key: [UInt8]) {
        guard let sorcID = self.sorcID else { return }
        enableEncryption(withSessionKey: key)
        connectionChange.onNext(.init(
            state: .connected(sorcID: sorcID),
            action: .connectionEstablished(sorcID: sorcID)
        ))
    }

    func challengerAbort(_: ChallengeError) {
        guard let sorcID = self.sorcID else { return }
        disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
    }

    func challengerNeedsSendBlob(latestBlobCounter: Int?) {
        guard let sorcID = self.sorcID, let messageCounter = leaseTokenBlob?.messageCounter else { return }
        if let counter = latestBlobCounter {
            handleBlobRequestDependingOnCounter(counterFromSorc: counter, localCounter: messageCounter, sorcId: sorcID)
        } else {
            sendBlob()
        }
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
