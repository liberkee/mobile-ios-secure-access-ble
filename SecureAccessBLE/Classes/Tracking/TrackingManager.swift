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

public enum ParameterKey: String {
    case group
    case message
    case timestamp
    case vehicleRef
    case sorcID
    case accessGrantID
    case version
    case phoneModel
    case osVersion
//    case builder
    case error
    case data // payload for response
}

public class TrackingManager {
    public var tracker: EventTracker?

    public var logLevel: LogLevel = .info
    public static var shared = TrackingManager()
    private let systemClock: SystemClockType

    internal init(systemClock: SystemClockType = SystemClock()) {
        self.systemClock = systemClock
    }

    internal func track(_ event: TrackEventType, parameters: [String: Any], loglevel: LogLevel) {
        if loglevel.rawValue <= logLevel.rawValue {
            var trackingParameter = parameters
            trackingParameter[ParameterKey.group.rawValue] = event.groupID()
            trackingParameter[ParameterKey.timestamp.rawValue] = systemClock.now()
            trackingParameter[ParameterKey.message.rawValue] = event.messageOfEvent()

            tracker?.trackEvent(String(describing: event), parameters: trackingParameter, loglevel: loglevel)
        }
    }
}

public func HSMTrack(_ event: TrackEventType, parameters: [String: Any], loglevel: LogLevel) {
    TrackingManager.shared.track(event, parameters: parameters, loglevel: loglevel)
}
