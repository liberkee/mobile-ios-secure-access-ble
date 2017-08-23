//
//  BLEManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile. All rights reserved.
//

import UIKit
import CryptoSwift
import CommonUtils

/**
 Defines the ServiceGrantTriggersStatus anwered from SORC, see also the definations for
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
 The BLEManager manages the communication with BLE peripherals
 */
public class BLEManager: NSObject, BLEManagerType {

    public static let shared = BLEManager()

    // MARK: - Public

    // MARK: Configuration

    // TODO: PLAM-959 update after init possible?

    public var heartbeatInterval: Double = 2000.0

    public var heartbeatTimeout: Double = 4000.0

    // MARK: Interface

    public var isBluetoothEnabled: BehaviorSubject<Bool> {
        return sorcConnectionManager.isPoweredOn
    }

    // MARK: Discovery

    public var discoveryChange: ChangeSubject<DiscoveryChange> {
        return sorcConnectionManager.discoveryChange
    }

    // MARK: Connection

    public var connectionChange: ChangeSubject<ConnectionChange> {
        return messageCommunicator.connectionChange
    }

    // MARK: Service

    public let receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    fileprivate let sorcConnectionManager: SorcConnectionManager
    fileprivate let messageCommunicator: SorcMessageCommunicator

    private let disposeBag = DisposeBag()

    // MARK: - Inits and deinit

    init(sorcConnectionManager: SorcConnectionManager, messageCommunicator: SorcMessageCommunicator) {
        self.sorcConnectionManager = sorcConnectionManager
        self.messageCommunicator = messageCommunicator
        super.init()

        messageCommunicator.messageReceived.subscribeNext { [weak self] result in
            self?.handleMessageReceived(result: result)
        }
        .disposed(by: disposeBag)
    }

    convenience override init() {
        let sorcConnectionManager = SorcConnectionManager()
        let dataCommunicator = SorcDataCommunicator(sorcConnectionManager: sorcConnectionManager)
        let messageCommunicator = SorcMessageCommunicator(dataCommunicator: dataCommunicator)
        self.init(sorcConnectionManager: sorcConnectionManager, messageCommunicator: messageCommunicator)
    }

    deinit {
        disconnect()
    }

    // MARK: Actions

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        messageCommunicator.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    public func disconnect() {
        messageCommunicator.disconnect()
    }

    public func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        guard messageCommunicator.isEncryptionEnabled && !messageCommunicator.isBusy else {
            let status = failedStatusMatchingFeature(feature)
            receivedServiceGrantTriggerForStatus.onNext((status: status, error: nil))
            return
        }

        let payload: SorcMessagePayload
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

        let message = SorcMessage(id: SorcMessageID.serviceGrant, payload: payload)
        _ = messageCommunicator.sendMessage(message)
    }

    // MARK: - Private methods

    private func handleMessageReceived(result: Result<SorcMessage>) {

        guard case .connected = messageCommunicator.connectionChange.state else { return }

        // TODO: PLAM-959: only handle this if connected established

        // TODO: PLAM-959 handle message error only once (heartbeat or service trigger?)

        let noValidDataErrorMessage = "No valid data was received"
        guard case let .success(message) = result else {
            // handleServiceGrantTrigger(nil, error: noValidDataErrorMessage)
            return
        }
        var error: String?

        guard message.id == SorcMessageID.serviceGrantTrigger else { return }

        var status: ServiceGrantTriggerStatus = .triggerStatusUnkown
        let trigger = ServiceGrantTrigger(rawData: message.message)

        switch trigger.id {
        case .lock: status = (trigger.status == .success) ? .lockSuccess : .lockFailed
        case .unlock: status = (trigger.status == .success) ? .unlockSuccess : .unlockFailed
        case .enableIgnition: status = (trigger.status == .success) ? .enableIgnitionSuccess : .enableIgnitionFailed
        case .disableIgnition: status = (trigger.status == .success) ? .disableIgnitionSuccess : .disableIgnitionFailed
        case .lockStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.locked {
                status = .lockStatusLocked
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.unlocked {
                status = .lockStatusUnlocked
            }
        case .ignitionStatus:
            if trigger.result == ServiceGrantTrigger.ServiceGrantResult.enabled {
                status = .ignitionStatusEnabled
            } else if trigger.result == ServiceGrantTrigger.ServiceGrantResult.disabled {
                status = .ignitionStatusDisabled
            }
        default:
            status = .triggerStatusUnkown
        }
        if status == .triggerStatusUnkown {
            print("BLEManager handleServiceGrantTrigger: Trigger status unknown.")
        }
        receivedServiceGrantTriggerForStatus.onNext((status: status, error: error))
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
}
