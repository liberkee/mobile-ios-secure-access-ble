//
//  BLEManager.swift
//  BLE
//
//  Created by Ke Song on 25.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CryptoSwift
import CommonUtils

/**
 Defines the ServiceGrantTriggersStatus anwered from SID, see also the definations for
 ServiceGrantID, ServiceGrantStatus and ServiceGrantResult defined in 'ServiceGrantTrigger.swift'
 */
public enum ServiceGrantTriggerStatus: Int {

    /// TriggerStatus Success for TriggerId:Lock
    case lockSuccess
    /// TriggerStatus NOT Success for TriggerId:Lock
    case lockFailed
    /// TriggerStatus Success for TriggerId:Unlock
    case unlockSuccess
    /// TriggerStatus NOT Success for TriggerId:Lock
    case unlockFailed
    /// TriggerStatus Success for TriggerId:EnableIgnition
    case enableIgnitionSuccess
    /// TriggerStatus NOT Success for TriggerId:EnableIgnition
    case enableIgnitionFailed
    /// TriggerStatus Success for TriggerId:DisableIgnition
    case disableIgnitionSuccess
    /// TriggerStatus NOT Success for TriggerId:DisableIgnition
    case disableIgnitionFailed
    /// TriggerStatus Locked for TriggerId:LockStatus
    case lockStatusLocked
    /// TriggerStatus Unlocked for TriggerId:LockStatus
    case lockStatusUnlocked
    /// TriggerStatus Enabled for TriggerId:LockStatus
    case ignitionStatusEnabled
    /// TriggerStatus Disabled for TriggerId:LockStatus
    case ignitionStatusDisabled
    /// other combination from triggerStatus and triggerResults
    case triggerStatusUnkown
}

/**
 Defination for sending message features as enumerating
 */
public enum ServiceGrantFeature {
    /// feature for unlocking cars door
    case open
    /// feature for locking cars door
    case close
    /// feature for enable engination
    case ignitionStart
    /// feature for disable engination
    case ignitionStop
    /// feature for calling up lock-status
    case lockStatus
    /// feature for calling up ignition-status
    case ignitionStatus
}

/**
 Define encryption state as enum
 */
enum EncryptionState {
    /// Encryption is required, but not established
    case shouldEncrypt
    /// Encryption is required and established
    case encryptionEstablished
}

/**
 Define connection status as enum
 */
enum ConnectionState {
    /// not connected status
    case notConnected
    /// connected status
    case connected
}

/**
 The BLEManager manages the communication with BLE peripherals
 */
public class BLEManager: NSObject, BLEManagerType {

    public static let shared = BLEManager()

    /// The Default MTU Size
    static var mtuSize = 20

    fileprivate var currentEncryptionState: EncryptionState

    /// Chanllenger object
    fileprivate var challenger: BLEChallengeService?
    ///  The communicator objec
    fileprivate let communicator: SIDCommunicator

    private var leaseID: String = ""
    private var leaseTokenID: String = ""
    private var sidAccessKey: String = ""
    fileprivate var sorcID: String = ""

    /// Blob as String came from SecureAccess.blob
    fileprivate var blobData: String? = ""

    /// Blob counter came from SecureAccess.blob
    fileprivate var blobCounter: Int = 0

    fileprivate var sendHeartbeatsTimer: Timer?

    fileprivate var checkHeartbeatsResponseTimer: Timer?

    fileprivate var lastHeartbeatResponseDate = Date()

    fileprivate let connectionManager: SorcConnectionManager

    private let disposeBag = DisposeBag()

    /**
     A object that must confirm to the CryptoManager protocol

     */
    fileprivate var cryptoManager: CryptoManager = ZeroSecurityManager()

    // MARK: - Inits and deinit

    init(sorcConnectionManager: SorcConnectionManager, communicator: SIDCommunicator) {
        currentEncryptionState = .shouldEncrypt
        connectionManager = sorcConnectionManager
        self.communicator = communicator
        super.init()
        communicator.delegate = self

        connectionManager.isPoweredOn.subscribeNext { [weak self] isPoweredOn in
            self?.isBluetoothEnabled.onNext(isPoweredOn)
        }
        .disposed(by: disposeBag)

        connectionManager.connectionChange.subscribeNext { [weak self] change in
            self?.handleTransferConnectionStateChange(change)
        }
        .disposed(by: disposeBag)
    }

    convenience override init() {
        let sorcConnectionManager = SorcConnectionManager()
        let communicator = SIDCommunicator(transporter: sorcConnectionManager)
        self.init(sorcConnectionManager: sorcConnectionManager, communicator: communicator)
    }

    /**
     Deinit point
     */
    deinit {
        disconnect()
    }

    // MARK: - Public

    // MARK: Configuration

    public var heartbeatInterval: Double = 2000.0

    public var heartbeatTimeout: Double = 4000.0

    // MARK: Interface

    public let isBluetoothEnabled = BehaviorSubject(value: false)

    // MARK: Discovery

    public var discoveryChange: ChangeSubject<DiscoveryChange> {
        return connectionManager.discoveryChange
    }

    // MARK: - Connection

    public let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    // MARK: Service

    public let receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: Actions

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sorcID = leaseToken.sorcID
        leaseTokenID = leaseToken.id
        leaseID = leaseToken.leaseID
        sidAccessKey = leaseToken.sorcAccessKey
        blobData = leaseTokenBlob.data
        blobCounter = leaseTokenBlob.messageCounter
        connectionManager.connectToSorc(sorcID)
    }

    public func disconnect() {
        connectionManager.disconnect()
    }

    private func reset() {
        communicator.resetCurrentPackage()
        cryptoManager = ZeroSecurityManager()
        currentEncryptionState = .shouldEncrypt
        stopSendingHeartbeat()
    }

    public func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        guard currentEncryptionState == .encryptionEstablished && !transferIsBusy() else {
            let status = failedStatusMatchingFeature(feature)
            receivedServiceGrantTriggerForStatus.onNext((status: status, error: nil))
            return
        }

        let payload: SIDMessagePayload
        switch feature {
        case .open:
            payload = ServiceGrantRequest(grantID: ServiceGrantID.unlock)
        case .close:
            payload = ServiceGrantRequest(grantID: ServiceGrantID.lock)
        case .ignitionStart:
            payload = ServiceGrantRequest(grantID: ServiceGrantID.enableIgnition)
        case .ignitionStop:
            payload = ServiceGrantRequest(grantID: ServiceGrantID.disableIgnition)
        case .lockStatus:
            payload = ServiceGrantRequest(grantID: ServiceGrantID.lockStatus)
        case .ignitionStatus:
            payload = ServiceGrantRequest(grantID: ServiceGrantID.ignitionStatus)
        }

        let message = SIDMessage(id: SIDMessageID.serviceGrant, payload: payload)
        _ = sendMessage(message)
    }

    // MARK: - Private methods

    private func handleTransferConnectionStateChange(_ change: SorcConnectionManager.ConnectionChange) {
        switch change.state {
        case let .connecting(sorcID):
            connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .physical),
                                          action: .connect(sorcID: sorcID)))
        case .connected:
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

    /**
     Helper function repots if the transfer currently busy

     - returns: Transfer busy
     */
    private func transferIsBusy() -> Bool {
        return communicator.currentPackage != nil
    }

    /**
     start timers for sending heartbeat and checking heartbeat response
     */
    fileprivate func bleSchouldSendHeartbeat() {
        sendHeartbeatsTimer = Timer.scheduledTimer(timeInterval: heartbeatInterval / 1000, target: self, selector: #selector(BLEManager.startSendingHeartbeat), userInfo: nil, repeats: true)
        checkHeartbeatsResponseTimer = Timer.scheduledTimer(timeInterval: heartbeatTimeout / 1000, target: self, selector: #selector(BLEManager.checkoutHeartbeatsResponse), userInfo: nil, repeats: true)
    }

    /**
     Sending heartbeats message to SID
     */
    func startSendingHeartbeat() {
        let message = SIDMessage(id: SIDMessageID.heartBeatRequest, payload: MTUSize())
        // TODO: PLAM-1375 handle error
        _ = self.sendMessage(message)
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
    func checkoutHeartbeatsResponse() {
        if (lastHeartbeatResponseDate.timeIntervalSinceNow + heartbeatTimeout / 1000) < 0 {
            disconnect(withAction: .connectionLost(error: .heartbeatTimedOut))
        }
    }

    fileprivate func sendMTURequest() {
        connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .requestingMTU),
                                      action: .physicalConnectionEstablished(sorcID: sorcID)))
        let message = SIDMessage(id: SIDMessageID.mtuRequest, payload: MTUSize())
        _ = self.sendMessage(message)
    }

    /**
     Initialize SID challenger to establish Crypto
     */
    fileprivate func establishCrypto() {
        if sorcID.isEmpty || sidAccessKey.isEmpty {
            print("Not found sorcID or access key for cram")
            disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            return
        }
        challenger = BLEChallengeService(leaseId: leaseID, sidId: sorcID, leaseTokenId: leaseTokenID, sidAccessKey: sidAccessKey)
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

    /**
     Sending Blob to SID peripheral
     */
    fileprivate func sendBlob() {
        if blobData?.isEmpty == false {
            if let payload = LTBlobPayload(blobData: blobData!) {
                let message = SIDMessage(id: .ltBlob, payload: payload)
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

    // TODO: It is only internal because of tests
    /**
     Sends data over the transporter
     When previous data is still in a sending state, the method will return **false** and an error message.
     Otherwise it will return **true** and a no error string (nil)

     - parameter message: The SIDMessage which should be send

     - returns:  (success: Bool, error: String?) A Tuple containing a success boolean and a error string or nil
     */
    func sendMessage(_ message: SIDMessage) -> (success: Bool, error: String?) {
        if communicator.currentPackage != nil {
            print("Sending package not empty!! Message \(message.id) will not be sent!!")
            return (false, "Sending in progress")
        } else {
            let data = cryptoManager.encryptMessage(message)
            return communicator.sendData(data)

            /*
             print("Send Encrypted Message: \(data.toHexString())")
             print("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
             let key = NSData.withBytes(self.cryptoManager.key)
             print("With key: \(key.toHexString())")
             */
        }
    }

    /**
     Response message from SID will be handled with reporting ServiceGrantTriggerStatus

     - parameter message: the Response message came from SID
     - parameter error:   error description if that not nil
     */
    fileprivate func handleServiceGrantTrigger(_ message: SIDMessage?, error: String?) {

        var theStatus: ServiceGrantTriggerStatus = .triggerStatusUnkown
        guard let trigger = message.map({ ServiceGrantTrigger(rawData: $0.message) }) else {
            receivedServiceGrantTriggerForStatus.onNext((status: theStatus, error: error))
            return
        }

        switch trigger.id {
        case .lock: theStatus = (trigger.status == .success) ? .lockSuccess : .lockFailed
        case .unlock: theStatus = (trigger.status == .success) ? .unlockSuccess : .unlockFailed
        case .enableIgnition: theStatus = (trigger.status == .success) ? .enableIgnitionSuccess : .enableIgnitionFailed
        case .disableIgnition: theStatus = (trigger.status == .success) ? .disableIgnitionSuccess : .disableIgnitionFailed
        case .lockStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.locked {
                theStatus = .lockStatusLocked
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.unlocked {
                theStatus = .lockStatusUnlocked
            }
        case .ignitionStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.enabled {
                theStatus = .ignitionStatusEnabled
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.disabled {
                theStatus = .ignitionStatusDisabled
            }
        default:
            theStatus = .triggerStatusUnkown
        }
        let error = error
        if theStatus == .triggerStatusUnkown {
            print("BLEManager handleServiceGrantTrigger: Trigger status unknown.")
        }
        receivedServiceGrantTriggerForStatus.onNext((status: theStatus, error: error))
    }

    private func failedStatusMatchingFeature(_ feature: ServiceGrantFeature) -> ServiceGrantTriggerStatus {
        switch feature {
        case .open:
            return .unlockFailed
        case .close:
            return .lockFailed
        case .ignitionStart:
            return .enableIgnitionFailed
        case .ignitionStop:
            return .disableIgnitionFailed
        default:
            return .triggerStatusUnkown
        }
    }

    fileprivate func disconnect(withAction action: ConnectionChange.Action) {
        connectionChange.onNext(.init(state: .disconnected, action: action))
        disconnect()
    }
}

// MARK: - BLEChallengeServiceDelegate

extension BLEManager: BLEChallengeServiceDelegate {

    func challengerWantsSendMessage(_ message: SIDMessage) {
        _ = sendMessage(message)
    }

    func challengerFinishedWithSessionKey(_ sessionKey: [UInt8]) {
        cryptoManager = AesCbcCryptoManager(key: sessionKey)
        currentEncryptionState = .encryptionEstablished
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

// MARK: - SIDCommunicatorDelegate

extension BLEManager: SIDCommunicatorDelegate {

    func communicatorDidReceivedData(_ messageData: Data, count: Int) {

        guard connectionManager.connectionChange.state == .connected(sorcID: sorcID) else { return }

        let noValidDataErrorMessage = "No valid data was received"

        guard messageData.count > 0 else {
            handleServiceGrantTrigger(nil, error: noValidDataErrorMessage)
            communicator.resetReceivedPackage()
            return
        }

        let message = cryptoManager.decryptData(messageData)
        guard message.id != .notValid else {
            handleServiceGrantTrigger(nil, error: noValidDataErrorMessage)
            communicator.resetReceivedPackage()
            return
        }

        let pointer = (messageData as NSData).bytes.bindMemory(to: UInt32.self, capacity: messageData.count)
        let count = count
        let buffer = UnsafeBufferPointer<UInt32>(start: pointer, count: count)
        _ = [UInt32](buffer)

        switch message.id {
            // MTU Size
        case .mtuReceive:
            let payload = MTUSize(rawData: message.message)
            if let mtu = payload.mtuSize {
                BLEManager.mtuSize = mtu
            }
            if currentEncryptionState == .shouldEncrypt {
                establishCrypto()
            }
            // Challenger Message
        case .challengeSidResponse, .badChallengeSidResponse, .ltAck:
            do {
                try challenger?.handleReceivedChallengerMessage(message)
            } catch {
                print("BLEManager Error: handleReceivedChallengerMessage failed message: \(message)")
                disconnect(withAction: .connectingFailed(sorcID: sorcID, error: .challengeFailed))
            }

        case .ltBlobRequest:
            let payload = BlobRequest(rawData: message.message)
            if blobCounter > payload.blobMessageId {
                sendBlob()
            }

        case .heartBeatResponse:
            lastHeartbeatResponseDate = Date()
            checkHeartbeatsResponseTimer?.fireDate = Date().addingTimeInterval(heartbeatTimeout / 1000)

        default:
            // Normal Message. E.g. ServiceGrant
            let messageID = message.id
            if messageID == SIDMessageID.serviceGrantTrigger {
                handleServiceGrantTrigger(message, error: nil)
            }
        }
        communicator.resetReceivedPackage()
    }
}
