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
    /// No encryption required
    case noEncryption
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

    fileprivate var currentConnectionState = ConnectionState.notConnected {
        didSet {
            if currentConnectionState == .notConnected {
                reset()
            }
            updateConnected(
                currentConnectionState: currentConnectionState,
                currentEncryptionState: currentEncryptionState
            )
        }
    }

    fileprivate var currentEncryptionState: EncryptionState {
        didSet {
            updateConnected(
                currentConnectionState: currentConnectionState,
                currentEncryptionState: currentEncryptionState
            )
        }
    }

    /// Chanllenger object
    fileprivate var challenger: BLEChallengeService?
    ///  The communicator objec
    fileprivate let communicator: SIDCommunicator

    /// DeviceId as String came from Userspace.Booking
    private var leaseId: String = ""

    /// LeaseToken Id as String came from SecureAccess.blob
    private var leaseTokenId: String = ""

    /// Sid AccessKey as String came from SecureAccess.blob
    private var sidAccessKey: String = ""

    /// SidId as String came from SecureAccess.leaseToken
    private var sidId: String = ""

    /// Blob as String came from SecureAccess.blob
    fileprivate var blobData: String? = ""

    /// Blob counter came from SecureAccess.blob
    fileprivate var blobCounter: Int = 0

    fileprivate var sendHeartbeatsTimer: Timer?

    fileprivate var checkHeartbeatsResponseTimer: Timer?

    fileprivate var lastHeartbeatResponseDate = Date()

    fileprivate let scanner = BLEScanner()

    /**
     A object that must confirm to the DataTransfer protocol

     Normally the transporter is a BLEScanner object
     */
    private var transporter: DataTransfer

    /**
     A object that must confirm to the CryptoManager protocol

     */
    fileprivate var cryptoManager: CryptoManager = ZeroSecurityManager()

    // MARK: - Inits and deinit

    /**
     Initial point for BLE-Manager

     - parameter crypto: if should be nedded cryption service
     - parameter sidID:  sid id, that BLE connecting to

     - returns: ble-manager object
     */
    init(crypto: Bool = false, sidID _: NSString = "") {
        if crypto == true {
            currentEncryptionState = .noEncryption
        } else {
            currentEncryptionState = .shouldEncrypt
        }
        transporter = scanner
        communicator = SIDCommunicator()
        communicator.transporter = transporter
        communicator.resetFoundSids()
        super.init()
        scanner.bleScannerDelegate = self
        communicator.delegate = self
    }

    /**
     Convenience Init with more parameters

     - parameter transporter: transfer object
     - parameter delegate:    delegate object
     - parameter crypto:      if cryption service needed

     - returns: BLE-Manager object
     */
    convenience init(transporter: BLEScanner, crypto: Bool = false, heartbeatInterval: Int, heartbeatTimeout: Int) {
        self.init(crypto: crypto)
        self.transporter = transporter
        self.heartbeatInterval = Double(heartbeatInterval)
        self.heartbeatTimeout = Double(heartbeatTimeout)
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

    public var isBluetoothEnabled = BehaviorSubject(value: false)

    // MARK: Discovery

    public func hasSorcId(_ sorcId: String) -> Bool {
        return communicator.hasSidID(sorcId)
    }

    public var sorcDiscovered = PublishSubject<SID>()

    public var sorcsLost = PublishSubject<[SID]>()

    // MARK: - Connection

    public var connected = BehaviorSubject<Bool>(value: false)

    public var connectedToSorc = PublishSubject<SID>()

    public var failedConnectingToSorc = PublishSubject<(sorc: SID, error: Error?)>()

    public var blobOutdated = PublishSubject<()>()

    // MARK: Service

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: Actions

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sidId = leaseToken.sorcId
        leaseTokenId = leaseToken.id
        leaseId = leaseToken.leaseId
        sidAccessKey = leaseToken.sorcAccessKey
        blobData = leaseTokenBlob.data
        blobCounter = leaseTokenBlob.messageCounter
        communicator.connectToSid(sidId)
    }

    public func disconnect() {
        if transporter.isConnected {
            transporter.disconnect()
        }
    }

    private func reset() {
        communicator.resetCurrentPackage()
        communicator.resetFoundSids()
        cryptoManager = ZeroSecurityManager()
        currentEncryptionState = .shouldEncrypt
        sendHeartbeatsTimer?.invalidate()
        checkHeartbeatsResponseTimer?.invalidate()
    }

    public func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        if currentEncryptionState == .encryptionEstablished && transferIsBusy() == false {
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
    }

    // MARK: - Private methods

    /**
     Helper function repots if the transfer currently busy

     - returns: Transfer busy
     */
    private func transferIsBusy() -> Bool {
        let transferIsBusy = communicator.currentPackage != nil
        print("The transfer is busy: \(transferIsBusy)")
        return transferIsBusy
    }

    /**
     start timers for sending heartbeat and checking heartbeat response
     */
    fileprivate func bleSchouldSendHeartbeat() {
        sendHeartbeatsTimer = Timer.scheduledTimer(timeInterval: heartbeatInterval / 1000, target: self, selector: #selector(BLEManager.startSendingHeartbeat), userInfo: nil, repeats: true)
        checkHeartbeatsResponseTimer = Timer.scheduledTimer(timeInterval: heartbeatTimeout / 1000, target: self, selector: #selector(BLEManager.checkoutHeartbeatsResponse), userInfo: nil, repeats: true)
    }

    /**
     stop the sending and checking heartbeat timers
     */
    fileprivate func stopSendingHeartbeat() {
        sendHeartbeatsTimer?.invalidate()
        checkHeartbeatsResponseTimer?.invalidate()
    }

    /**
     Sending heartbeats message to SID
     */
    func startSendingHeartbeat() {
        let message = SIDMessage(id: SIDMessageID.heartBeatRequest, payload: MTUSize())
        // TODO: handle error
        _ = self.sendMessage(message)
    }

    /**
     check out connection state if timer for checkheartbeat response fired
     */
    func checkoutHeartbeatsResponse() {
        print("check heartbeats Response!")
        if (lastHeartbeatResponseDate.timeIntervalSinceNow + heartbeatTimeout / 1000) < 0 {
            currentConnectionState = .notConnected
        }
    }

    /**
     Initialize SID challenger to establish Crypto
     */
    fileprivate func establishCrypto() {
        if sidId.isEmpty || sidAccessKey.isEmpty {
            print("Not found sidId or access key for cram")
            return
        }
        challenger = BLEChallengeService(leaseId: leaseId, sidId: sidId, leaseTokenId: leaseTokenId, sidAccessKey: sidAccessKey)
        challenger?.delegate = self
        if challenger == nil {
            print("Cram could not be initialized")
            return
        }
        do {
            try challenger?.beginChallenge()
        } catch {
            print("Will be both BLE and Comm. disconnected!")
            disconnect()
        }
    }

    /**
     To send Mtu - message
     */
    fileprivate func sendMtuRequest() {
        let message = SIDMessage(id: SIDMessageID.mtuRequest, payload: MTUSize())
        _ = self.sendMessage(message)
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
            }
        } else {
            print("Blob data error")
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
            print("Package: \(String(describing: communicator.currentPackage?.message))")
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
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Locked {
                theStatus = .lockStatusLocked
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Unlocked {
                theStatus = .lockStatusUnlocked
            }
        case .ignitionStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Enabled {
                theStatus = .ignitionStatusEnabled
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Disabled {
                theStatus = .ignitionStatusDisabled
            }
        default:
            theStatus = .triggerStatusUnkown
        }
        let error = error
        if theStatus == .triggerStatusUnkown {
            print("Trigger status unkown!!")
        }
        receivedServiceGrantTriggerForStatus.onNext((status: theStatus, error: error))
    }

    private func updateConnected(currentConnectionState: ConnectionState, currentEncryptionState: EncryptionState) {
        let connectedState = currentConnectionState == .connected
        let encryptionEstablished = currentEncryptionState == .encryptionEstablished
        let isConnectedSecurely = connectedState && encryptionEstablished
        if connected.value != isConnectedSecurely {
            connected.onNext(isConnectedSecurely)
        }
    }
}

// MARK: - BLEScannerDelegate

extension BLEManager: BLEScannerDelegate {

    public func didUpdateState() {
        isBluetoothEnabled.onNext(scanner.isPoweredOn())
    }
}

// MARK: - BLEChallengeServiceDelegate

extension BLEManager: BLEChallengeServiceDelegate {

    /**
     SID challenger reports to send SID a message

     - parameter message: the message that will be sent to SID peripheral
     */
    func challengerWantsSendMessage(_ message: SIDMessage) {
        _ = sendMessage(message)
    }

    /**
     SID challenger reports finished with extablishing SessionKey

     - parameter sessionKey: Crypto key for initializing CryptoManager
     */
    func challengerFinishedWithSessionKey(_ sessionKey: [UInt8]) {
        cryptoManager = AesCbcCryptoManager(key: sessionKey)
        currentEncryptionState = .encryptionEstablished
        bleSchouldSendHeartbeat()
    }

    /**
     SID challenger reports abort with challenge

     - parameter error: error descriptiong for Cram Unit
     */
    func challengerAbort(_: BLEChallengerError) {
        disconnect()
    }

    /**
     SID challenger reports to need send Blob to SID peripheral
     */
    func challengerNeedsSendBlob(latestBlobCounter: Int?) {

        guard latestBlobCounter == nil || blobCounter >= latestBlobCounter! else {
            print("Ask user to get latest blob")
            blobOutdated.onNext()
            return
        }
        sendBlob()
    }
}

// MARK: - SIDCommunicatorDelegate

extension BLEManager: SIDCommunicatorDelegate {

    /**
     Communicator reports did received response data

     - parameter messageData: received data
     - parameter count:       received data length
     */
    func communicatorDidRecivedData(_ messageData: Data, count: Int) {

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
                print("Will be both BLE and Comm. disconnected!")
                disconnect()
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

    /**
     Communicator reports if connection state did changed

     - parameter connected: is connected or not
     */
    func communicatorDidChangedConnectionState(_ connected: Bool) {
        if connected {
            currentConnectionState = .connected
            sendMtuRequest()
        } else {
            currentConnectionState = .notConnected
        }
    }

    /**

     Communicator reports if new SID was discovered

     - parameter newSid: the found SID object
     */
    func comminicatorDidDiscoveredSidId(_ newSid: SID) {
        sorcDiscovered.onNext(newSid)
    }

    /**
     Communicator reports if there are SIDs longer as 5 seconds not reported

     - parameter oldSid: did lost SIDs as Array
     */
    func communicatorDidLostSidIds(_ oldSids: [SID]) {
        sorcsLost.onNext(oldSids)
    }

    /**
     Communicator reports if a connection attempt succeeded

     - parameter communicator: The communicator object
     - parameter sid: The SID the connection is made to
     */
    func communicatorDidConnectSid(_: SIDCommunicator, sid: SID) {
        // TODO: this has to be advanced to cover further communication between device and sid
        // it is only used for metrics at the moment
        connectedToSorc.onNext(sid)
    }

    /**
     Communicator reports if a connection attempt failed

     - parameter communicator: The communicator object
     - parameter sid: The SID the connection should have made to
     - parameter error: Describes the error
     */
    func communicatorDidFailToConnectSid(_: SIDCommunicator, sid: SID, error: Error?) {
        // TODO: this has to be advanced to cover further communication between device and sid
        // it is only used for metrics at the moment
        failedConnectingToSorc.onNext((sorc: sid, error: error))
    }
}
