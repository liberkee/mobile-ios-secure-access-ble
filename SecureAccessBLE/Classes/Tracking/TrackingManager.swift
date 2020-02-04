//
//  TrackingManager.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 04.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public protocol EventTracker {
    func trackEvent(_ event: String, message: String, parameters: [String: Any])
}

enum Event: String {
    enum Group: String {
        case discovery = "Discovery"
        case connection = "Connection"
        case vehicleAccess = "VehicleAccess"
        case telematics = "Telematics"
        case keyholder = "Keyholder"
    }

    case discoveryStartedByApp
    case discoveryStarted
    case discoveryCancelledbyApp
    case discoveryStopped
    case discoverySuccessful
    case discoveryLost

    case connectionStartedByApp
    case connectionStarted
    case connectionTranferringBLOB
    case connectionEstablished
    case connectionCancelledByApp
    case connectionDisconnected

    case doorsLockRequested
    case doorsLocked
    case doorsLockFailed
    case doorsUnlockRequested
    case doorsUnlocked
    case doorsUnlockFailed

    case engineEnableRequested
    case engineEnabled
    case engineEnableFailed
    case engineDisableRequested
    case engineDisabled
    case engineDisableFailed

    case doorsStatusRequested
    case doorsStatusReceived
    case doorsStatusFailed
    case engineStatusRequested
    case engineStatusReceived
    case engineStatusFailed

    case telematicsRequested
    case telematicsReceived
    case telematicsRequestedFailed

    case locationRequested
    case locationReceived
    case locationRequestfailed

    case keyholderStatusRequested
    case keyholderStatusReceived
    case keyholderStatusFailed

    var group: String {
        switch self {
        case .discoveryStartedByApp,
             .discoveryStarted,
             .discoveryCancelledbyApp,
             .discoveryStopped,
             .discoverySuccessful,
             .discoveryLost:
            return Group.discovery.rawValue
        case .connectionStartedByApp,
             .connectionStarted,
             .connectionTranferringBLOB,
             .connectionEstablished,
             .connectionCancelledByApp,
             .connectionDisconnected:
            return Group.connection.rawValue
        case .doorsLockRequested,
             .doorsLocked,
             .doorsLockFailed,
             .doorsUnlockRequested,
             .doorsUnlocked,
             .doorsUnlockFailed,
             .engineEnableRequested,
             .engineEnabled,
             .engineEnableFailed,
             .engineDisableRequested,
             .engineDisabled,
             .engineDisableFailed,
             .doorsStatusRequested,
             .doorsStatusReceived,
             .doorsStatusFailed,
             .engineStatusRequested,
             .engineStatusReceived,
             .engineStatusFailed:
            return Group.vehicleAccess.rawValue
        case .telematicsRequested,
             .telematicsReceived,
             .telematicsRequestedFailed,
             .locationReceived,
             .locationRequested,
             .locationRequestfailed:
            return Group.telematics.rawValue
        case .keyholderStatusRequested,
             .keyholderStatusReceived,
             .keyholderStatusFailed:
            return Group.keyholder.rawValue
        }
    }
}

public class TrackingManager {
    public var tracker: EventTracker?

    init() {}

    private var systemClock: SystemClockType = SystemClock()

    func track(_ event: Event, message: String, parameters: [String: Any]) {
        var trackingParameter = parameters
        trackingParameter["group"] = event.group
        trackingParameter["timestamp"] = systemClock.now()
        tracker?.trackEvent(event.rawValue, message: message, parameters: trackingParameter)
    }
}
