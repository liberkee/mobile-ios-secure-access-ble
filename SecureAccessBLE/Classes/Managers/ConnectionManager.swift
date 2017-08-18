//
//  ConnectionManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile. All rights reserved.
//

import Foundation
import CommonUtils

class ConnectionManager {

    let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    var heartbeatInterval: Double = 2000.0
    var heartbeatTimeout: Double = 4000.0

    private var challenger: BLEChallengeService?

    private var leaseID: String = ""
    private var leaseTokenID: String = ""
    private var sorcAccessKey: String = ""
    fileprivate var sorcID: SorcID = ""
    private var blobData: String? = ""
    fileprivate var blobCounter: Int = 0

    fileprivate var sendHeartbeatsTimer: Timer?
    fileprivate var checkHeartbeatsResponseTimer: Timer?
    fileprivate var lastHeartbeatResponseDate = Date()

    private let sorcConnectionManager: SorcConnectionManager
    fileprivate let messageCommunicator: SorcMessageCommunicator

    private let disposeBag = DisposeBag()

    init(sorcConnectionManager: SorcConnectionManager, messageCommunicator: SorcMessageCommunicator) {
        self.sorcConnectionManager = sorcConnectionManager
        self.messageCommunicator = messageCommunicator

        sorcConnectionManager.connectionChange.subscribeNext { [weak self] change in
            self?.handleTransferConnectionStateChange(change)
        }
        .disposed(by: disposeBag)

        messageCommunicator.messageReceived.subscribeNext { [weak self] result in
            self?.handleMessageReceived(result: result)
        }
        .disposed(by: disposeBag)
    }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sorcID = leaseToken.sorcID
        leaseTokenID = leaseToken.id
        leaseID = leaseToken.leaseID
        sorcAccessKey = leaseToken.sorcAccessKey
        blobData = leaseTokenBlob.data
        blobCounter = leaseTokenBlob.messageCounter
        sorcConnectionManager.connectToSorc(sorcID)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    fileprivate func disconnect(withAction action: ConnectionChange.Action) {
        reset()
        connectionChange.onNext(.init(state: .disconnected, action: action))
        sorcConnectionManager.disconnect()
    }

    private func reset() {
        messageCommunicator.reset()
        stopSendingHeartbeat()
    }

    private func sendMTURequest() {
        let message = SorcMessage(id: SorcMessageID.mtuRequest, payload: MTUSize())
        _ = messageCommunicator.sendMessage(message)
    }

    private func establishCrypto() {
        if sorcID.isEmpty || sorcAccessKey.isEmpty {
            print("Not found sorcID or access key for cram")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }
        challenger = BLEChallengeService(leaseID: leaseID, sorcID: sorcID, leaseTokenID: leaseTokenID, sorcAccessKey: sorcAccessKey)
        challenger?.delegate = self
        if challenger == nil {
            print("Cram could not be initialized")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }
        do {
            try challenger?.beginChallenge()
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .challenging),
                                          action: .mtuRequested(sorcID: sorcID)))
        } catch {
            print("BLEManager Error: beginChallenge error: \(error)")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    fileprivate func sendBlob() {
        if blobData?.isEmpty == false {
            if let payload = LTBlobPayload(blobData: blobData!) {
                let message = SorcMessage(id: .ltBlob, payload: payload)
                _ = messageCommunicator.sendMessage(message)
            } else {
                print("Blob data error")
                disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            }
        } else {
            print("Blob data error")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    /**
     start timers for sending heartbeat and checking heartbeat response
     */
    fileprivate func bleSchouldSendHeartbeat() {
        sendHeartbeatsTimer = Timer.scheduledTimer(timeInterval: heartbeatInterval / 1000, target: self,
                                                   selector: #selector(ConnectionManager.startSendingHeartbeat),
                                                   userInfo: nil, repeats: true)
        checkHeartbeatsResponseTimer = Timer.scheduledTimer(timeInterval: heartbeatTimeout / 1000, target: self,
                                                            selector: #selector(ConnectionManager.checkoutHeartbeatsResponse),
                                                            userInfo: nil, repeats: true)
    }

    /**
     Sending heartbeats message to SORC
     */
    @objc func startSendingHeartbeat() {
        let message = SorcMessage(id: SorcMessageID.heartBeatRequest, payload: MTUSize())
        // TODO: PLAM-1375 handle error
        _ = messageCommunicator.sendMessage(message)
    }

    /**
     stop the sending and checking heartbeat timers
     */
    fileprivate func stopSendingHeartbeat() {
        sendHeartbeatsTimer?.invalidate()
        checkHeartbeatsResponseTimer?.invalidate()
    }

    /**
     check out connection state if timer for checkheartbeat response fired
     */
    @objc func checkoutHeartbeatsResponse() {
        if (lastHeartbeatResponseDate.timeIntervalSinceNow + heartbeatTimeout / 1000) < 0 {
            disconnect(withAction: .connectionLost(error: .heartbeatTimedOut))
        }
    }

    // MARK: - Private methods

    private func handleTransferConnectionStateChange(_ change: DataConnectionChange) {
        switch change.state {
        case let .connecting(sorcID):
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .physical),
                                          action: .connect(sorcID: sorcID)))
        case .connected:
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

    private func handleMessageReceived(result: Result<SorcMessage>) {

        guard sorcConnectionManager.connectionChange.state == .connected(sorcID: sorcID) else { return }

        let noValidDataErrorMessage = "No valid data was received"
        guard case let .success(message) = result else {

            // TODO: PLAM-959 handle message error only once

            // handleServiceGrantTrigger(nil, error: noValidDataErrorMessage)
            return
        }

        switch message.id {
        case .mtuReceive:
            if !messageCommunicator.isEncryptionEnabled {
                establishCrypto()
            }
        case .challengeSorcResponse, .badChallengeSorcResponse, .ltAck:
            do {
                try challenger?.handleReceivedChallengerMessage(message)
            } catch {
                print("BLEManager Error: handleReceivedChallengerMessage failed message: \(message)")
                disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            }
        case .ltBlobRequest:
            let payload = BlobRequest(rawData: message.message)
            if blobCounter > payload.blobMessageID {
                sendBlob()
            }
        case .heartBeatResponse:
            lastHeartbeatResponseDate = Date()
            checkHeartbeatsResponseTimer?.fireDate = Date().addingTimeInterval(heartbeatTimeout / 1000)
        default: break
        }
    }
}

// MARK: - BLEChallengeServiceDelegate

extension ConnectionManager: BLEChallengeServiceDelegate {

    func challengerWantsSendMessage(_ message: SorcMessage) {
        _ = messageCommunicator.sendMessage(message)
    }

    func challengerFinishedWithSessionKey(_ key: [UInt8]) {
        messageCommunicator.enableEncryption(withSessionKey: key)
        connectionChange.onNext(.init(
            state: .connected(sorcID: sorcID),
            action: .connectionEstablished(sorcID: sorcID))
        )
        bleSchouldSendHeartbeat()
    }

    func challengerAbort(_: BLEChallengerError) {
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
