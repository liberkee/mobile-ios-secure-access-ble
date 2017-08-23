//
//  SorcMessageCommunicator.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Sends and receives SORC messages. Handles encryption/decryption.
class SorcMessageCommunicator {

    enum Error: Swift.Error, CustomStringConvertible {
        case receivedInvalidData

        var description: String {
            return "Invalid data was received."
        }
    }

    let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)
    let messageReceived = PublishSubject<Result<SorcMessage>>()

    /// TODO: PLAM-959 Communicate back if a message was sent so that queuing becomes possible?
    var isBusy: Bool {
        return dataCommunicator.isBusy
    }

    /// TODO: PLAM-959 Remove, because connected means encrypted
    var isEncryptionEnabled: Bool {
        return cryptoManager is AesCbcCryptoManager
    }

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

    private let dataCommunicator: SorcDataCommunicator
    private var cryptoManager: CryptoManager = ZeroSecurityManager()
    private let disposeBag = DisposeBag()

    init(dataCommunicator: SorcDataCommunicator) {
        self.dataCommunicator = dataCommunicator

        dataCommunicator.connectionChange.subscribeNext { [weak self] change in
            self?.handleTransportConnectionChange(change)
        }
        .disposed(by: disposeBag)

        dataCommunicator.dataReceived.subscribeNext { [weak self] data in
            self?.handleDataReceived(data: data)
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
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .physical),
                                          action: .connect(sorcID: sorcID)))
        }

        dataCommunicator.connectToSorc(sorcID)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    /**
     Sends data over the transporter
     When previous data is still in a sending state, the method will return **false** and an error message.
     Otherwise it will return **true** and a no error string (nil)

     - parameter message: The SorcMessage which should be send

     - returns:  (success: Bool, error: String?) A Tuple containing a success boolean and a error string or nil
     */
    func sendMessage(_ message: SorcMessage) -> (success: Bool, error: String?) {
        // TODO: PLAM-959 add preconditions, use proper encryption

        if dataCommunicator.isBusy {
            print("Sending package not empty!! Message \(message.id) will not be sent!!")
            return (false, "Sending in progress")
        } else {
            let data = cryptoManager.encryptMessage(message)
            return dataCommunicator.sendData(data)

            /*
             print("Send Encrypted Message: \(data.toHexString())")
             print("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
             let key = NSData.withBytes(self.cryptoManager.key)
             print("With key: \(key.toHexString())")
             */
        }
    }

    // MARK: - Private methods

    fileprivate func enableEncryption(withSessionKey key: [UInt8]) {
        cryptoManager = AesCbcCryptoManager(key: key)
    }

    fileprivate func disconnect(withAction action: ConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        reset()
        connectionChange.onNext(.init(state: .disconnected, action: action))
        dataCommunicator.disconnect()
    }

    private func reset() {
        cryptoManager = ZeroSecurityManager()
        stopSendingHeartbeat()
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
                                          action: .transportConnectionEstablished(sorcID: sorcID)))
        } catch {
            print("BLEManager Error: beginChallenge error: \(error)")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
        }
    }

    fileprivate func sendBlob() {
        if blobData?.isEmpty == false {
            if let payload = LTBlobPayload(blobData: blobData!) {
                let message = SorcMessage(id: .ltBlob, payload: payload)
                _ = sendMessage(message)
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
                                                   selector: #selector(SorcMessageCommunicator.startSendingHeartbeat),
                                                   userInfo: nil, repeats: true)
        checkHeartbeatsResponseTimer = Timer.scheduledTimer(timeInterval: heartbeatTimeout / 1000, target: self,
                                                            selector: #selector(SorcMessageCommunicator.checkoutHeartbeatsResponse),
                                                            userInfo: nil, repeats: true)
    }

    /**
     Sending heartbeats message to SORC
     */
    @objc func startSendingHeartbeat() {
        let message = SorcMessage(id: SorcMessageID.heartBeatRequest, payload: MTUSize())
        // TODO: PLAM-1375 handle error
        _ = sendMessage(message)
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

    private func handleTransportConnectionChange(_ transportChange: TransportConnectionChange) {

        switch transportChange.state {
        case let .connecting(transportSorcID, transportConnectingState):
            switch transportConnectingState {
            case .physical: break
            case .requestingMTU:
                guard case let .connecting(sorcID, .physical) = connectionChange.state, sorcID == transportSorcID else {
                    return
                }
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .transport),
                                              action: .physicalConnectionEstablished(sorcID: sorcID)))
            }
        case let .connected(sorcID):
            guard connectionChange.state == .connecting(sorcID: sorcID, state: .transport) else { return }
            establishCrypto()
        case .disconnected:
            if connectionChange.state == .disconnected { return }
            reset()
            switch transportChange.action {
            case let .connectingFailed(sorcID, transportError):
                let error: ConnectingFailedError
                switch transportError {
                case .physicalConnectingFailed:
                    error = .physicalConnectingFailed
                case .transportConnectingFailed:
                    error = .transportConnectingFailed
                }
                connectionChange.onNext(.init(state: .disconnected,
                                              action: .connectingFailed(sorcID: sorcID, error: error)))
            case .disconnect:
                connectionChange.onNext(.init(state: .disconnected, action: .disconnect))
            case let .connectionLost(transportError):
                let error: ConnectionLostError
                switch transportError {
                case .physicalConnectionLost:
                    error = .physicalConnectionLost
                }
                connectionChange.onNext(.init(state: .disconnected, action: .connectionLost(error: error)))
            default: break
            }
        }
    }

    private func handleDataReceived(data: Data) {
        switch connectionChange.state {
        case .connecting(_, .challenging):
            handleDataReceivedWhileChallenging(data: data)
        case .connected:
            handleDataReceivedWhileConnected(data: data)
        default:
            return
        }
    }

    private func handleDataReceivedWhileChallenging(data: Data) {
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

    private func handleDataReceivedWhileConnected(data: Data) {
        let message = cryptoManager.decryptData(data)

        if case .heartBeatResponse = message.id {
            handleHeartbeatResponse()
            return
        }

        guard message.id != .notValid else {
            messageReceived.onNext(.error(Error.receivedInvalidData))
            return
        }
        messageReceived.onNext(.success(message))
    }

    private func handleHeartbeatResponse() {
        lastHeartbeatResponseDate = Date()
        checkHeartbeatsResponseTimer?.fireDate = Date().addingTimeInterval(heartbeatTimeout / 1000)
    }
}

// MARK: - BLEChallengeServiceDelegate

extension SorcMessageCommunicator: BLEChallengeServiceDelegate {

    func challengerWantsSendMessage(_ message: SorcMessage) {
        _ = sendMessage(message)
    }

    func challengerFinishedWithSessionKey(_ key: [UInt8]) {
        enableEncryption(withSessionKey: key)
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
