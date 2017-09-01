//
//  BLEManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CryptoSwift
import CommonUtils

/**
 Defines the ServiceGrantTriggersStatus anwered from SORC, see also the definations for
 FeatureServiceGrantID, ServiceGrantStatus and ServiceGrantResult defined in 'ServiceGrantTrigger.swift'
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

enum FeatureServiceGrantID: UInt16 {
    /// To unlock vehicles door
    case unlock = 0x01
    /// To lock vehicles door
    case lock = 0x02
    /// To call up vehicles lock status
    case lockStatus = 0x03
    /// To enable Ignition
    case enableIgnition = 0x04
    /// To disable Ignition
    case disableIgnition = 0x05
    /// To call up Ignition status
    case ignitionStatus = 0x06
    /// Others
    case notValid = 0xFF
}

/**
 Is the Service Grant response to a Trigger service Grant request message defined as enumerating

 - Locked:   Door was Locked
 - Unlocked: Door was Unlocked
 - Enabled:  Ignition was enabled
 - Disabled: Ignition was disabled
 - Unknown:  Unknown result
 */
enum FeatureResult: String {
    case locked = "LOCKED"
    case unlocked = "UNLOCKED"
    case enabled = "ENABLED"
    case disabled = "DISABLED"
    case unknown = "UNKNOWN"
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

    public var isBluetoothEnabled: StateSignal<Bool> {
        return sorcManager.isBluetoothEnabled
    }

    // MARK: Discovery

    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return sorcManager.discoveryChange
    }

    // MARK: Connection

    public var connectionChange: ChangeSignal<ConnectionChange> {
        return sorcManager.connectionChange
    }

    // MARK: Service

    public var receivedServiceGrantTriggerForStatus: EventSignal<(status: ServiceGrantTriggerStatus?, error: String?)> {
        return receivedServiceGrantTriggerForStatusSubject.asSignal()
    }

    private let receivedServiceGrantTriggerForStatusSubject = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    fileprivate let sorcManager: SorcManagerType

    private let disposeBag = DisposeBag()

    // MARK: - Inits and deinit

    init(sorcManager: SorcManagerType) {
        self.sorcManager = sorcManager
        super.init()

        sorcManager.serviceGrantResultReceived.subscribe { [weak self] result in
            self?.handleServiceGrantResult(result)
        }
        .disposed(by: disposeBag)
    }

    convenience override init() {
        self.init(sorcManager: SorcManager())
    }

    deinit {
        disconnect()
    }

    // MARK: Actions

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sorcManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    public func disconnect() {
        sorcManager.disconnect()
    }

    public func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        guard case .connected = sorcManager.connectionChange.state else { return }

        let serviceGrantID: FeatureServiceGrantID
        switch feature {
        case .open:
            serviceGrantID = .unlock
        case .close:
            serviceGrantID = .lock
        case .ignitionStart:
            serviceGrantID = .enableIgnition
        case .ignitionStop:
            serviceGrantID = .disableIgnition
        case .lockStatus:
            serviceGrantID = .lockStatus
        case .ignitionStatus:
            serviceGrantID = .ignitionStatus
        }

        sorcManager.requestServiceGrant(serviceGrantID.rawValue)
    }

    // MARK: - Private methods

    private func handleServiceGrantResult(_ result: ServiceGrantResult) {

        // PLAM-959: needs work

        guard case .connected = sorcManager.connectionChange.state else { return }

        guard case let .success(response) = result else {
            receivedServiceGrantTriggerForStatusSubject.onNext(
                (status: .triggerStatusUnkown, error: "Service grant result failure.")
            )
            return
        }

        var status: ServiceGrantTriggerStatus = .triggerStatusUnkown

        let serviceGrantID = FeatureServiceGrantID(rawValue: response.serviceGrantID) ?? .notValid
        switch serviceGrantID {
        case .lock:
            status = (response.status == .success) ? .lockSuccess : .lockFailed
        case .unlock:
            status = (response.status == .success) ? .unlockSuccess : .unlockFailed
        case .enableIgnition:
            status = (response.status == .success) ? .enableIgnitionSuccess : .enableIgnitionFailed
        case .disableIgnition:
            status = (response.status == .success) ? .disableIgnitionSuccess : .disableIgnitionFailed
        case .lockStatus:
            let resultCode = resultCodeForResponseData(response.responseData)
            switch resultCode {
            case .locked:
                status = .lockStatusLocked
            case .unlocked:
                status = .lockStatusUnlocked
            default: break
            }
        case .ignitionStatus:
            let resultCode = resultCodeForResponseData(response.responseData)
            switch resultCode {
            case .enabled:
                status = .ignitionStatusEnabled
            case .disabled:
                status = .ignitionStatusDisabled
            default: break
            }
        default:
            status = .triggerStatusUnkown
        }
        if status == .triggerStatusUnkown {
            print("BLEManager handleServiceGrantTrigger: Trigger status unknown.")
        }
        receivedServiceGrantTriggerForStatusSubject.onNext((status: status, error: nil))
    }

    private func resultCodeForResponseData(_ data: String) -> FeatureResult {
        guard !data.isEmpty,
            let resultCode = FeatureResult(rawValue: data)
        else { return .unknown }
        return resultCode
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
