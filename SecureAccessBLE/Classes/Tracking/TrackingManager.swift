//
//  TrackingManager.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 04.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public protocol EventTracker {
    func trackEvent(_ event: String, parameters: [String: Any], loglevel: LogLevel)
}

public protocol LogID {
    func toString() -> String
    func groupID() -> String
    func messageOfEvent() -> String
}

internal enum SAEvent: String, LogID {
    func toString() -> String {
        rawValue
    }

    func groupID() -> String {
        return group
    }

    func messageOfEvent() -> String {
        return message
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

    var group: String {
        switch self {
        case .discoveryStartedByApp,
             .discoveryStarted,
             .discoveryCancelledbyApp,
             .discoveryStopped,
             .discoverySuccessful,
             .discoveryLost:
            return "Discovery"
        case .connectionStartedByApp,
             .connectionStarted,
             .connectionTranferringBLOB,
             .connectionEstablished,
             .connectionCancelledByApp,
             .connectionDisconnected:
            return "Connection"
        }
    }

    var message: String {
        switch self {
        case .discoveryStartedByApp:
            return "Discovery was started by App"
        case .discoveryStarted:
            return "Discovery was started"
        case .discoveryCancelledbyApp:
            return "Discovery was cancelled was App"
        case .discoveryStopped:
            return "Discovery was stopped"
        case .discoverySuccessful:
            return "Discovery was completed successfully"
        case .discoveryLost:
            return "Discovery was lost"
        case .connectionStartedByApp:
            return "Connection request by App"
        case .connectionStarted:
            return "Connection request"
        case .connectionTranferringBLOB:
            return "Connection transferring BLOB"
        case .connectionEstablished:
            return "Connection is established"
        case .connectionCancelledByApp:
            return "Connection is cancelled by App"
        case .connectionDisconnected:
            return "Connection is disconnected"
        }
    }
}

public enum parameterKey: String {
    case group
    case message
    case timestamp
    case vehicleRef
    case sorcID
    case accessGrantID
    case version
    case phoneModel
    case osVersion
    case builder
    case error
}

public class TrackingManager {
    public var tracker: EventTracker?

    public var logLevel: LogLevel = .info
    public static var shared = TrackingManager()
    private var systemClock: SystemClockType = SystemClock()

    internal func track(_ event: LogID, parameters: [String: Any], loglevel: LogLevel) {
        if logLevel.toString() == loglevel.toString() {
            var trackingParameter = parameters
            trackingParameter[parameterKey.group.rawValue] = event.groupID()
            trackingParameter[parameterKey.timestamp.rawValue] = systemClock.now()
            trackingParameter[parameterKey.message.rawValue] = event.messageOfEvent()

            tracker?.trackEvent(event.toString(), parameters: trackingParameter, loglevel: loglevel)
        }
    }
}

public func HSMTracker(_ event: LogID, parameters: [String: Any], loglevel: LogLevel) {
    TrackingManager.shared.track(event, parameters: parameters, loglevel: loglevel)
}
