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
    func bleDidReceivedServiceTriggerForStatus(status: ServiceGrantTriggerStatus?, error: String?)
    
    /**
     BLE changed connection status
     
     - parameter isConnected: currently connected or not
     */
    func bleDidChangedConnectionState(isConnected: Bool)
    
    /**
     BLE discovered new sid
     
     - parameter newSid: new found SID object
     */
    func bleDidDiscoveredSidId(newSid: SID)
    
    /**
     BLE reports lost of old sids
     
     - parameter oldSids: the lost old sids as array
     */
    func bleDidLostSidIds(oldSids: [SID])
}

// MARK: - Extension point for BLEmanager delegate
public extension BLEManagerDelegate {
    /**
     BLE reports, received service grant trgger
     
     - parameter status: service grant trigger status
     - parameter error:  error description
     */
    func bleDidReceivedServiceTriggerForStatus(status: ServiceGrantTriggerStatus?, error: String?) {}
    
    /**
     BLE changed connection status
     
     - parameter isConnected: currently connected or not
     */
    func bleDidChangedConnectionState(isConnected: Bool) {}
    
    /**
     BLE discovered new sid
     
     - parameter newSid: new found SID object
     */
    func bleDidDiscoveredSidId(newSid: SID) {}
    
    /**
     BLE reports lost of old sids
     
     - parameter oldSids: the lost old sids as array
     */
    func bleDidLostSidIds(oldSids: [SID]) {}
}

/**
 Defines the ServiceGrantTriggersStatus anwered from SID, see also the definations for
 ServiceGrantID, ServiceGrantStatus and ServiceGrantResult defined in 'ServiceGrantTrigger.swift'
 */
public enum ServiceGrantTriggerStatus: Int {
    
    /// TriggerStatus Success for TriggerId:Lock
    case LockSuccess
    /// TriggerStatus NOT Success for TriggerId:Lock
    case LockFailed
    /// TriggerStatus Success for TriggerId:Unlock
    case UnlockSuccess
    /// TriggerStatus NOT Success for TriggerId:Lock
    case UnlockFailed
    /// TriggerStatus Success for TriggerId:EnableIgnition
    case EnableIgnitionSuccess
    /// TriggerStatus NOT Success for TriggerId:EnableIgnition
    case EnableIgnitionFailed
    /// TriggerStatus Success for TriggerId:DisableIgnition
    case DisableIgnitionSuccess
    /// TriggerStatus NOT Success for TriggerId:DisableIgnition
    case DisableIgnitionFailed
    /// TriggerStatus Locked for TriggerId:LockStatus
    case LockStatusLocked
    /// TriggerStatus Unlocked for TriggerId:LockStatus
    case LockStatusUnlocked
    /// TriggerStatus Enabled for TriggerId:LockStatus
    case IgnitionStatusEnabled
    /// TriggerStatus Disabled for TriggerId:LockStatus
    case IgnitionStatusDisabled
    /// other combination from triggerStatus and triggerResults
    case TriggerStatusUnkown
}

/**
 Defination for sending message features as enumerating
 */
public enum ServiceGrantFeature {
    /// feature for unlocking cars door
    case Open
    /// feature for locking cars door
    case Close
    /// feature for enable engination
    case IgnitionStart
    /// feature for disable engination
    case IgnitionStop
    /// feature for calling up lock-status
    case LockStatus
    /// feature for calling up ignition-status
    case IgnitionStatus
}

/**
 Define encryption state as enum
 */
enum EncryptionState {
    /// No encryption required
    case NoEncryption
    /// Encryption is required, but not established
    case ShouldEncrypt
    /// Encryption is required and established
    case EncryptionEstablished
}

/**
 Define connection status as enum
 */
enum ConnectionState {
    /// not connected status
    case NotConnected
    /// connected status
    case Connected
}

/**
 The BLEManager represents the TransportLayer
*/
public class BLEComManager: NSObject, BLEChallengeServiceDelegate, SIDCommunicatorDelegate {
    
    ///The Default MTU Size
    static var mtuSize = 20
    
    /// The netto message size (MTU minus frame header information)
    var messageFrameSize: Int {
        return BLEComManager.mtuSize - 4
    }
    
    ///The connection state
    public var isConnected: Bool {
        let connectedState = self.currentConnectionState == .Connected
        //let encryptionNoState = self.currentEncryptionState == .NoEncryption
        let encryptionEstablished = self.currentEncryptionState == .EncryptionEstablished
        //print("connected? \(self.currentConnectionState) NoEncryption?: \(encryptionNoState) EncryptionEstablished?: \(encryptionEstablished)")
        return connectedState && encryptionEstablished//(encryptionNoState || encryptionEstablished)
    }
    
    /// Connection state, default as .Notconnected
    private var currentConnectionState = ConnectionState.NotConnected {
        didSet {
            print("State changed now: \(currentConnectionState)")
        }
    }
    
    /// Encryption state
    private var currentEncryptionState: EncryptionState
    /// Chanllenger object
    private var challenger: BLEChallengeService?
    ///  The communicator objec
    private var communicator: SIDCommunicator?
    /// DeviceId as String came from Userspace.Booking
    public var deviceId: String = ""
    
    /// LeaseToken Id as String came from SecureAccess.blob
    public var leaseTokenId: String = ""
    /// Sid AccessKey as String came from SecureAccess.blob
    public var sidAccessKey: String = ""
    /// SidId as String came from SecureAccess.leaseToken
    public var sidId: String  = ""
    /// Blob as String came from SecureAccess.blob
    private var blobData: String?  = ""
    /// Blob counter came from SecureAccess.blob
    private var blobCounter: Int = 0
    /// time interval Ble should send heartbeat to SID
    public var heartbeatInterval:Double = 2000.0
    /// time out the ble should waite for heartbeat response
    public var heartbeatTimeout:Double = 4000.0
    
    private var sendHeartbeatsTimer: NSTimer?
    
    private var checkHeartbeatsResponseTimer: NSTimer?
    
    private var lastHeartbeatResponseDate = NSDate()
    
    /**
    A object that must confirm to the DataTransfer protocol
    
    Normally the transporter is a BLEScanner object
    */
    var transporter: DataTransfer
    
    /**
    A object that must confirm to the CryptoManager protocol
    
    */
    private var cryptoManager: CryptoManager = ZeroSecurityManager()
    
    ///The delegate must confirm to the BLEManagerDelegate Protocol
    public weak var delegate: BLEManagerDelegate?
    
    /**
     Initial point for BLE-Manager
     
     - parameter crypto: if should be nedded cryption service
     - parameter sidID:  sid id, that BLE connecting to
     
     - returns: ble-manager object
     */
    required public init(crypto: Bool = false, sidID: NSString = "") {
        if crypto == true {
            self.currentEncryptionState = .NoEncryption
        } else {
            self.currentEncryptionState = .ShouldEncrypt
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
    public func transferIsBusy() -> Bool {
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
    public func connectToSid(sidId: String, blobData: String?, blobCounter: Int) {
        self.sidId = sidId
        self.blobData = blobData
        self.blobCounter = blobCounter
        self.communicator?.connectToSid(sidId)
    }
    
    /**
     start timers for sending heartbeat and checking heartbeat response
     */
    private func bleSchouldSendHeartbeat() {
        self.sendHeartbeatsTimer = NSTimer.scheduledTimerWithTimeInterval(self.heartbeatInterval/1000, target: self, selector: #selector(BLEComManager.startSendingHeartbeat), userInfo: nil, repeats: true)
        self.checkHeartbeatsResponseTimer = NSTimer.scheduledTimerWithTimeInterval(self.heartbeatTimeout/1000, target: self, selector: #selector(BLEComManager.checkoutHeartbeatsResponse), userInfo: nil, repeats: true)
    }
    
    /**
     stop the sending and checking heartbeat timers
     */
    private func stopSendingHeartbeat() {
        self.sendHeartbeatsTimer?.invalidate()
        self.checkHeartbeatsResponseTimer?.invalidate()
    }
    
    /**
     Sending heartbeats message to SID
     */
    func startSendingHeartbeat() {
        //print("sending heartbeat!")
        let message = SIDMessage(id: SIDMessageID.HeartBeatRequest, payload: MTUSize())
        self.sendMessage(message)
    }
    
    /**
     check out connection state if timer for checkheartbeat response fired
     */
    func checkoutHeartbeatsResponse() {
        print("check heartbeats Response!")
        if (self.lastHeartbeatResponseDate.timeIntervalSinceNow + self.heartbeatTimeout/1000) < 0 {
            self.currentConnectionState = .NotConnected
        }
        self.delegate?.bleDidChangedConnectionState(self.currentConnectionState == .Connected)
    }
    
    /**
     Disconnects from current sid
     */
    public func disconnect() {
        print("COM-Manager will be disconnected!")
        self.communicator?.resetCurrentPackage()
        self.communicator?.resetFoundSids()
        self.currentEncryptionState = .ShouldEncrypt
        self.cryptoManager = ZeroSecurityManager()
        self.sendHeartbeatsTimer?.invalidate()
        self.checkHeartbeatsResponseTimer?.invalidate()
    }
    
    /**
     To disconnect dataTransfer
     */
    public func disconnectTransporter() {
        if self.transporter.isConnected {
            self.transporter.disconnect()
        }
    }
    
    /**
     Checks if a SID ID is already discovered.
     
     - parameter sidId: A SID ID string
     
     - returns: When already in list it returns true, otherwise false.
     */
    public func hasSidID(sidId: String) -> Bool {
        return (self.communicator?.hasSidID(sidId))!
    }
    
    /**
     Initialize SID challenger to establish Crypto
     */
    private func establishCrypto() {
        if self.sidId.isEmpty || self.sidAccessKey.isEmpty {
            print("Not found sidId or access key for cram")
            return
        }
        self.challenger = BLEChallengeService(deviceId: self.deviceId, sidId: self.sidId, leaseTokenId: self.leaseTokenId, sidAccessKey: self.sidAccessKey)
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
    public func sendServiceGrantForFeature(feature: ServiceGrantFeature) {
        if self.currentEncryptionState == .EncryptionEstablished && self.transferIsBusy() == false {
            let payload: SIDMessagePayload
            var stopPayload: SIDMessagePayload?
            switch feature {
            case .Open:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.Unlock)
            case .Close:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.Lock)
                stopPayload = ServiceGrantRequest(grantID: ServiceGrantID.DisableIgnition)
            case .IgnitionStart:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.EnableIgnition)
            case .IgnitionStop:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.DisableIgnition)
            case .LockStatus:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.LockStatus)
            case .IgnitionStatus:
                payload = ServiceGrantRequest(grantID: ServiceGrantID.IgnitionStatus)
            }
            
            let message = SIDMessage(id: SIDMessageID.ServiceGrant, payload: payload)
            self.sendMessage(message)
            
            if let stop = stopPayload {
                Delay(0.5, closure: { () -> () in
                    let message = SIDMessage(id: SIDMessageID.ServiceGrant, payload: stop)
                    self.sendMessage(message)
                })
            }
        }
    }
    
    /**
     To send Mtu - message
     */
    private func sendMtuRequest() {
        let message = SIDMessage(id: SIDMessageID.MTURequest, payload: MTUSize())
        self.sendMessage(message)
    }
    
    /**
     Sending Blob to SID peripheral
     */
    private func sendBlob() {
        if self.blobData?.isEmpty == false {
            if let payload = LTBlobPayload(blobData: blobData!)
            {
                let message = SIDMessage(id: .LTBlob, payload: payload)
                self.sendMessage(message)
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
    func sendMessage(message: SIDMessage) -> (success: Bool, error: String?) {
        if self.communicator?.currentPackage != nil {
            print("Sending package not empty!! Message \(message.id) will not be sent!!")
            print("Package: \(self.communicator?.currentPackage?.message)")
            return (false, "Sending in progress")
        } else {
            let data = self.cryptoManager.encryptMessage(message)
            self.communicator?.sendData(data)
            //print("----------------------------------------")
//            print("Send Encrypted Message: \(data.toHexString())")
//            print("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
            //let key = NSData.withBytes(self.cryptoManager.key)
            //print("With key: \(key.toHexString())")
            //print("-----------  sended message with id: \(message.id) -------------")
        }
        return (true, nil)
    }
    
    /**
     Response message from SID will be handled with reporting ServiceGrantTriggerStatus
    
     - parameter message: the Response message came from SID
     - parameter error:   error description if that not nil
     */
    func handleServiceGrantTrigger(message: SIDMessage?, error: String?) {
        let trigger = ServiceGrantTrigger(rawData: message!.message)
        var theStatus = ServiceGrantTriggerStatus.TriggerStatusUnkown
        
        switch trigger.id {
        case .Lock: theStatus = (trigger.status == .Success) ? .LockSuccess : .LockFailed
        case .Unlock: theStatus = (trigger.status == .Success) ? .UnlockSuccess : .UnlockFailed
        case .EnableIgnition: theStatus = (trigger.status == .Success) ? .EnableIgnitionSuccess : .EnableIgnitionFailed
        case .DisableIgnition: theStatus = (trigger.status == .Success) ? .DisableIgnitionSuccess : .DisableIgnitionFailed
        case .LockStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Locked {
                theStatus = .LockStatusLocked
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Unlocked {
                theStatus = .LockStatusUnlocked
            }
        case .IgnitionStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Enabled {
                theStatus = .IgnitionStatusEnabled
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.Disabled {
                theStatus = .IgnitionStatusDisabled
            }
        default:
            theStatus = .TriggerStatusUnkown
        }
        let error = error
        if theStatus == .TriggerStatusUnkown {
            print("Trigger status unkown!!")
        }
        self.delegate?.bleDidReceivedServiceTriggerForStatus(theStatus, error: error)
    }
    
//MARK: - SIDChallengerDelegate
    /**
     SID challenger reports to send SID a message
     
     - parameter message: the message that will be sent to SID peripheral
     */
    func challengerWantsSendMessage(message: SIDMessage) {
        //print ("cram send message!")
        self.sendMessage(message)
    }
    
    /**
     SID challenger reports finished with extablishing SessionKey
     
     - parameter sessionKey: Crypto key for initializing CryptoManager
     */
    func challengerFinishedWithSessionKey(sessionKey: [UInt8]) {
        self.cryptoManager = AesCbcCryptoManager(key: sessionKey)
        self.currentEncryptionState = .EncryptionEstablished
        self.delegate?.bleDidChangedConnectionState(true)
        self.bleSchouldSendHeartbeat()
    }
    
    /**
     SID challenger reports abort with challenge
     
     - parameter error: error descriptiong for Cram Unit
     */
    func challengerAbort(error: BLEChallengerError) {
        self.disconnect()
        self.disconnectTransporter()
    }
    
    /**
     SID challenger reports to need send Blob to SID peripheral
     */
    func challengerNeedsSendBlob() {
       self.sendBlob()
    }
    
//MARK: - SIDCommunicatorDelegate
    /**
     Communicator reports did received response data
     
     - parameter messageData: received data
     - parameter count:       received data length
     */
    func communicatorDidRecivedData(messageData: NSData, count: Int) {
        if messageData.length == 0 {
            self.handleServiceGrantTrigger(nil, error: "No valid data was received")
        } else {
            let message = self.cryptoManager.decryptData(messageData)
            let pointer = UnsafePointer<UInt32>(messageData.bytes)
            let count = count
            let buffer = UnsafeBufferPointer<UInt32>(start:pointer, count:count)
            let array = [UInt32](buffer)
            //print ("received Data array:\(array) for message id:\(message.id)")
            
            switch message.id {
            //MTU Size
            case .MTUReceive:
                let payload = MTUSize(rawData: message.message)
                if let mtu = payload.mtuSize {
                    BLEComManager.mtuSize = mtu
                }
                if self.currentEncryptionState == .ShouldEncrypt {
                    self.establishCrypto()
                } else {
                    self.delegate?.bleDidChangedConnectionState(true)
                }
                
            //Challenger Message
            case .ChallengeSidResponse, .BadChallengeSidResponse, .LTAck:
                do {
                    try self.challenger?.handleReceivedChallengerMessage(message)
                } catch {
                    print("Will be both BLE and Comm. disconnected!")
                    self.disconnect()
                    self.disconnectTransporter()
                }
                
            case .LTBlobRequest:
                let payload = BlobRequest(rawData: message.message)
                if self.blobCounter > payload.blobMessageId {
                    self.sendBlob()
                }
                
            case .HeartBeatResponse:
                self.lastHeartbeatResponseDate = NSDate()
                self.checkHeartbeatsResponseTimer?.fireDate = NSDate().dateByAddingTimeInterval(self.heartbeatTimeout/1000)
                
            default:
                //Normal Message. E.g. ServiceGrant
                let messageID = message.id
                if messageID == SIDMessageID.ServiceGrantTrigger {
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
    func communicatorDidChangedConnectionState(connected: Bool) {
        if connected {
            self.currentConnectionState = .Connected
            self.sendMtuRequest()
        } else {
            print("Will be both BLE and Comm. disconnected!")
            //self.disconnect()
            self.currentConnectionState = .NotConnected
        }
        //self.delegate?.bleDidChangedConnectionState(connected)
    }
    
    /**
     Communicator reports if new SID was discovered
     
     - parameter newSid: the found SID object
     */
    func comminicatorDidDiscoveredSidId(newSid: SID) {
        self.delegate?.bleDidDiscoveredSidId(newSid)
    }
    
    /**
     Communicator reports if there are SIDs longer as 5 seconds not reported
     
     - parameter oldSid: did lost SIDs as Array
     */
    func communicatorDidLostSidIds(oldSids: [SID]) {
        self.delegate?.bleDidLostSidIds(oldSids)
    }
}
