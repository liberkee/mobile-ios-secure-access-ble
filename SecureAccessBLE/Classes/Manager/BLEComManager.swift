//
//  BLEManager.swift
//  BLE
//
//  Created by Ke Song on 25.06.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CryptoSwift

/// All delegate functions, BLE manager offers
public protocol BLEManagerDelegate: class {
    /**
     BLE reports, received service grant trgger
     
     - parameter status: service grant trigger status
     - parameter error:  error description
     */
    func bleDidReceivedServiceTriggerForStatus(_ status: ServiceGrantTriggerStatus?, error: String?)
    
    /**
     BLE changed connection status
     
     - parameter isConnected: currently connected or not
     */
    func bleDidChangedConnectionState(_ isConnected: Bool)
    
    /**
     BLE discovered new sid
     
     - parameter newSid: new found SID object
     */
    func bleDidDiscoveredSidId(_ newSid: SID)
    
    /**
     BLE reports lost of old sids
     
     - parameter oldSids: the lost old sids as array
     */
    func bleDidLostSidIds(_ oldSids: [SID])
    
    /**
     BLE reports blob needs to be updated, because the user is sending an out of date blob token
     */
    func blobIsOutdated()
}

// MARK: - Extension point for BLEmanager delegate
public extension BLEManagerDelegate {
    /**
     BLE reports, received service grant trgger
     
     - parameter status: service grant trigger status
     - parameter error:  error description
     */
    func bleDidReceivedServiceTriggerForStatus(_ status: ServiceGrantTriggerStatus?, error: String?) {}
    
    /**
     BLE changed connection status
     
     - parameter isConnected: currently connected or not
     */
    func bleDidChangedConnectionState(_ isConnected: Bool) {}
    
    /**
     BLE discovered new sid
     
     - parameter newSid: new found SID object
     */
    func bleDidDiscoveredSidId(_ newSid: SID) {}
    
    /**
     BLE reports lost of old sids
     
     - parameter oldSids: the lost old sids as array
     */
    func bleDidLostSidIds(_ oldSids: [SID]) {}
}

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
 The BLEManager represents the TransportLayer
*/
open class BLEComManager: NSObject, BLEChallengeServiceDelegate, SIDCommunicatorDelegate {
    
    ///The Default MTU Size
    static var mtuSize = 20
    
    /// The netto message size (MTU minus frame header information)
    var messageFrameSize: Int {
        return BLEComManager.mtuSize - 4
    }
    
    ///The connection state
    open var isConnected: Bool {
        let connectedState = self.currentConnectionState == .connected
        let encryptionEstablished = self.currentEncryptionState == .encryptionEstablished
        print("connected? \(self.currentConnectionState) EncryptionEstablished?: \(encryptionEstablished)")
        return connectedState && encryptionEstablished
    }
    
    /// Connection state, default as .Notconnected
    fileprivate var currentConnectionState = ConnectionState.notConnected {
        didSet {
            print("State changed now: \(currentConnectionState)")
        }
    }
    
    /// Encryption state
    fileprivate var currentEncryptionState: EncryptionState
    /// Chanllenger object
    fileprivate var challenger: BLEChallengeService?
    ///  The communicator objec
    fileprivate var communicator: SIDCommunicator?
    /// DeviceId as String came from Userspace.Booking
    open var leaseId: String = ""
    
    /// LeaseToken Id as String came from SecureAccess.blob
    open var leaseTokenId: String = ""
    /// Sid AccessKey as String came from SecureAccess.blob
    open var sidAccessKey: String = ""
    /// SidId as String came from SecureAccess.leaseToken
    open var sidId: String  = ""
    /// Blob as String came from SecureAccess.blob
    fileprivate var blobData: String?  = ""
    /// Blob counter came from SecureAccess.blob
    fileprivate var blobCounter: Int = 0
    /// time interval Ble should send heartbeat to SID
    open var heartbeatInterval:Double = 2000.0
    /// time out the ble should waite for heartbeat response
    open var heartbeatTimeout:Double = 4000.0
    
    fileprivate var sendHeartbeatsTimer: Timer?
    
    fileprivate var checkHeartbeatsResponseTimer: Timer?
    
    fileprivate var lastHeartbeatResponseDate = Date()
    
    /**
    A object that must confirm to the DataTransfer protocol
    
    Normally the transporter is a BLEScanner object
    */
    var transporter: DataTransfer
    
    /**
    A object that must confirm to the CryptoManager protocol
    
    */
    fileprivate var cryptoManager: CryptoManager = ZeroSecurityManager()
    
    ///The delegate must confirm to the BLEManagerDelegate Protocol
    open weak var delegate: BLEManagerDelegate?
    
    /**
     Initial point for BLE-Manager
     
     - parameter crypto: if should be nedded cryption service
     - parameter sidID:  sid id, that BLE connecting to
     
     - returns: ble-manager object
     */
    required public init(crypto: Bool = false, sidID: NSString = "") {
        if crypto == true {
            self.currentEncryptionState = .noEncryption
        } else {
            self.currentEncryptionState = .shouldEncrypt
        }
        self.transporter = BLEScanner()
        super.init()
        self.communicator = SIDCommunicator.init()
        self.communicator?.transporter = self.transporter
        self.communicator?.resetFoundSids()
        self.communicator?.delegate = self
    }
    
    /**
     Convenience Init with more parameters
     
     - parameter transporter: transfer object
     - parameter delegate:    delegate object
     - parameter crypto:      if cryption service needed
     
     - returns: BLE-Manager object
     */
    convenience init(transporter: BLEScanner, delegate: BLEManagerDelegate, crypto: Bool = false, heartbeatInterval: Int, heartbeatTimeout: Int) {
        self.init(crypto: crypto)
        self.transporter = transporter
        self.heartbeatInterval = Double(heartbeatInterval)
        self.heartbeatTimeout = Double(heartbeatTimeout)
        self.delegate = delegate
    }
    /**
     Deinit point
     */
    deinit {
        print("Will be both BLE and Comm. disconnected!")
        self.disconnect()
        self.disconnectTransporter()
    }
    
    /**
     Helper function repots if the transfer currently busy
     
     - returns: Transfer busy
     */
    open func transferIsBusy() -> Bool {
        let transferIsBusy = self.communicator?.currentPackage != nil
        print("The transfer is busy: \(transferIsBusy)")
        return transferIsBusy
    }
    
    
//MARK: - Private and public used functions
    /**
     Connects to a spefific SID
     
     - parameter sidId:       The Id of the SID, it should be connected to
     - parameter blobData:    blobdata as String see also SecureAccess.Blob
     - parameter blobCounter: blobs messageCounter see also SecureAccess.Blob
     */
    open func connectToSid(_ sidId: String, blobData: String?, blobCounter: Int) {
        self.sidId = sidId
        self.blobData = blobData
        self.blobCounter = blobCounter
        self.communicator?.connectToSid(sidId)
    }
    
    /**
     start timers for sending heartbeat and checking heartbeat response
     */
    fileprivate func bleSchouldSendHeartbeat() {
        self.sendHeartbeatsTimer = Timer.scheduledTimer(timeInterval: self.heartbeatInterval/1000, target: self, selector: #selector(BLEComManager.startSendingHeartbeat), userInfo: nil, repeats: true)
        self.checkHeartbeatsResponseTimer = Timer.scheduledTimer(timeInterval: self.heartbeatTimeout/1000, target: self, selector: #selector(BLEComManager.checkoutHeartbeatsResponse), userInfo: nil, repeats: true)
    }
    
    /**
     stop the sending and checking heartbeat timers
     */
    fileprivate func stopSendingHeartbeat() {
        self.sendHeartbeatsTimer?.invalidate()
        self.checkHeartbeatsResponseTimer?.invalidate()
    }
    
    /**
     Sending heartbeats message to SID
     */
    func startSendingHeartbeat() {
        let message = SIDMessage(id: SIDMessageID.heartBeatRequest, payload: MTUSize())
        let _ = self.sendMessage(message)
    }
    
    /**
     check out connection state if timer for checkheartbeat response fired
     */
    func checkoutHeartbeatsResponse() {
        print("check heartbeats Response!")
        if (self.lastHeartbeatResponseDate.timeIntervalSinceNow + self.heartbeatTimeout/1000) < 0 {
            self.currentConnectionState = .notConnected
        }
        self.delegate?.bleDidChangedConnectionState(self.currentConnectionState == .connected)
    }
    
    /**
     Disconnects from current sid
     */
    open func disconnect() {
        print("COM-Manager will be disconnected!")
        self.communicator?.resetCurrentPackage()
        self.communicator?.resetFoundSids()
        self.currentEncryptionState = .shouldEncrypt
        self.cryptoManager = ZeroSecurityManager()
        self.sendHeartbeatsTimer?.invalidate()
        self.checkHeartbeatsResponseTimer?.invalidate()
    }
    
    /**
     To disconnect dataTransfer
     */
    open func disconnectTransporter() {
        if self.transporter.isConnected {
            self.transporter.disconnect()
        }
    }
    
    /**
     Checks if a SID ID is already discovered.
     
     - parameter sidId: A SID ID string
     
     - returns: When already in list it returns true, otherwise false.
     */
    open func hasSidID(_ sidId: String) -> Bool {
        return (self.communicator?.hasSidID(sidId))!
    }
    
    /**
     Initialize SID challenger to establish Crypto
     */
    fileprivate func establishCrypto() {
        if self.sidId.isEmpty || self.sidAccessKey.isEmpty {
            print("Not found sidId or access key for cram")
            return
        }
        self.challenger = BLEChallengeService(leaseId: self.leaseId, sidId: self.sidId, leaseTokenId: self.leaseTokenId, sidAccessKey: self.sidAccessKey)
        self.challenger?.delegate = self
        if self.challenger == nil {
            print("Cram could not be initialized")
            return
        }
        do {
            try self.challenger?.beginChallenge()
        } catch {
            print("Will be both BLE and Comm. disconnected!")
            self.disconnect()
            self.disconnectTransporter()
        }
    }
    
//MARK: - Communication with SID Peripheral
    /**
     Communicating connected SID with sending messages, that was builed from serviceGrant request with
     id as messages payload
     
     - parameter feature: defined features to identifier the target SidMessage id
     */
    open func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        if self.currentEncryptionState == .encryptionEstablished && self.transferIsBusy() == false {
            let payload: SIDMessagePayload
            var stopPayload: SIDMessagePayload?
            switch feature {
            case .open:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.unlock)
            case .close:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.lock)
                stopPayload = ServiceGrantRequest(grantID: ServiceGrantID.disableIgnition)
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
            let _ = self.sendMessage(message)
            
            if let stop = stopPayload {
                Delay(0.5, closure: { () -> () in
                    let message = SIDMessage(id: SIDMessageID.serviceGrant, payload: stop)
                    let _ = self.sendMessage(message)
                })
            }
        }
    }
    
    /**
     To send Mtu - message
     */
    fileprivate func sendMtuRequest() {
        let message = SIDMessage(id: SIDMessageID.mtuRequest, payload: MTUSize())
        let _ = self.sendMessage(message)
    }
    
    /**
     Sending Blob to SID peripheral
     */
    fileprivate func sendBlob() {
        if self.blobData?.isEmpty == false {
            if let payload = LTBlobPayload(blobData: blobData!)
            {
                let message = SIDMessage(id: .ltBlob, payload: payload)
                let _ = self.sendMessage(message)
            } else {
                print("Blob data error")
            }
        } else {
            print("Blob data error")
        }
    }
    
    /**
     Sends data over the transporter
     When previous data is still in a sending state, the method will return **false** and an error message.
     Otherwise it will return **true** and a no error string (nil)
     
     - parameter message: The SIDMessage which should be send
     
     - returns:  (success: Bool, error: String?) A Tuple containing a success boolean and a error string or nil
     */
    func sendMessage(_ message: SIDMessage) -> (success: Bool, error: String?) {
        if self.communicator?.currentPackage != nil {
            print("Sending package not empty!! Message \(message.id) will not be sent!!")
            print("Package: \(self.communicator?.currentPackage?.message)")
            return (false, "Sending in progress")
        } else {
            let data = self.cryptoManager.encryptMessage(message)
            let _ = self.communicator?.sendData(data)
            
            /*
            print("Send Encrypted Message: \(data.toHexString())")
            print("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
            let key = NSData.withBytes(self.cryptoManager.key)
            print("With key: \(key.toHexString())")
            */
        }
        return (true, nil)
    }
    
    /**
     Response message from SID will be handled with reporting ServiceGrantTriggerStatus
    
     - parameter message: the Response message came from SID
     - parameter error:   error description if that not nil
     */
    func handleServiceGrantTrigger(_ message: SIDMessage?, error: String?) {
        let trigger = ServiceGrantTrigger(rawData: message!.message)
        var theStatus = ServiceGrantTriggerStatus.triggerStatusUnkown
        
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
        self.delegate?.bleDidReceivedServiceTriggerForStatus(theStatus, error: error)
    }
    
//MARK: - SIDChallengerDelegate
    /**
     SID challenger reports to send SID a message
     
     - parameter message: the message that will be sent to SID peripheral
     */
    func challengerWantsSendMessage(_ message: SIDMessage) {
        let _ = self.sendMessage(message)
    }
    
    /**
     SID challenger reports finished with extablishing SessionKey
     
     - parameter sessionKey: Crypto key for initializing CryptoManager
     */
    func challengerFinishedWithSessionKey(_ sessionKey: [UInt8]) {
        self.cryptoManager = AesCbcCryptoManager(key: sessionKey)
        self.currentEncryptionState = .encryptionEstablished
        self.delegate?.bleDidChangedConnectionState(true)
        self.bleSchouldSendHeartbeat()
    }
    
    /**
     SID challenger reports abort with challenge
     
     - parameter error: error descriptiong for Cram Unit
     */
    func challengerAbort(_ error: BLEChallengerError) {
        self.disconnect()
        self.disconnectTransporter()
    }
    
    /**
     SID challenger reports to need send Blob to SID peripheral
     */
    func challengerNeedsSendBlob(latestBlobCounter:Int?) {
        
        guard latestBlobCounter == nil || blobCounter >= latestBlobCounter!  else {
            print("Ask user to get latest blob")
            self.delegate?.blobIsOutdated()
            return
        }
        self.sendBlob()
    }
    
//MARK: - SIDCommunicatorDelegate
    /**
     Communicator reports did received response data
     
     - parameter messageData: received data
     - parameter count:       received data length
     */
    func communicatorDidRecivedData(_ messageData: Data, count: Int) {
        if messageData.count == 0 {
            self.handleServiceGrantTrigger(nil, error: "No valid data was received")
        } else {
            let message = self.cryptoManager.decryptData(messageData)
            let pointer = (messageData as NSData).bytes.bindMemory(to: UInt32.self, capacity: messageData.count)
            let count = count
            let buffer = UnsafeBufferPointer<UInt32>(start:pointer, count:count)
            _ = [UInt32](buffer)
            
            switch message.id {
            //MTU Size
            case .mtuReceive:
                let payload = MTUSize(rawData: message.message)
                if let mtu = payload.mtuSize {
                    BLEComManager.mtuSize = mtu
                }
                if self.currentEncryptionState == .shouldEncrypt {
                    self.establishCrypto()
                } else {
                    self.delegate?.bleDidChangedConnectionState(true)
                }
                
            //Challenger Message
            case .challengeSidResponse, .badChallengeSidResponse, .ltAck:
                do {
                    try self.challenger?.handleReceivedChallengerMessage(message)
                } catch {
                    print("Will be both BLE and Comm. disconnected!")
                    self.disconnect()
                    self.disconnectTransporter()
                }
                
            case .ltBlobRequest:
                let payload = BlobRequest(rawData: message.message)
                if self.blobCounter > payload.blobMessageId {
                    self.sendBlob()
                }
                
            case .heartBeatResponse:
                self.lastHeartbeatResponseDate = Date()
                self.checkHeartbeatsResponseTimer?.fireDate = Date().addingTimeInterval(self.heartbeatTimeout/1000)
                
            default:
                //Normal Message. E.g. ServiceGrant
                let messageID = message.id
                if messageID == SIDMessageID.serviceGrantTrigger {
                    self.handleServiceGrantTrigger(message, error: nil)
                }
            }
        }
        self.communicator?.resetReceivedPackage()
    }
    
    /**
     Communicator reports if connection state did changed
     
     - parameter connected: is connected or not
     */
    func communicatorDidChangedConnectionState(_ connected: Bool) {
        if connected {
            self.currentConnectionState = .connected
            self.sendMtuRequest()
        } else {
            print("Will be both BLE and Comm. disconnected!")
            self.currentConnectionState = .notConnected
        }
    }
    
    /**
     Communicator reports if new SID was discovered
     
     - parameter newSid: the found SID object
     */
    func comminicatorDidDiscoveredSidId(_ newSid: SID) {
        self.delegate?.bleDidDiscoveredSidId(newSid)
    }
    
    /**
     Communicator reports if there are SIDs longer as 5 seconds not reported
     
     - parameter oldSid: did lost SIDs as Array
     */
    func communicatorDidLostSidIds(_ oldSids: [SID]) {
        self.delegate?.bleDidLostSidIds(oldSids)
    }
}
