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
    private var tracker: EventTracker?

    private var logLevel: LogLevel = .info
    private let systemClock: SystemClockType
    public static var shared = TrackingManager()

    /// :nodoc
    // Set to true to filter out events which should not be reported to TACS Framework since it tracks them on its own
    public var usedByTACSSDK: Bool = false

    public func registerTracker(_ tracker: EventTracker, logLevel: LogLevel) {
        self.tracker = tracker
        self.logLevel = logLevel
    }

    internal init(systemClock: SystemClockType = SystemClock()) {
        self.systemClock = systemClock
    }

    internal func track(_ event: TrackingEvent, parameters: [String: Any] = [:], loglevel: LogLevel) {
        if usedByTACSSDK, !event.shouldBeReportedToTacs {
            return
        }
        if loglevel.rawValue <= logLevel.rawValue {
            // Prefer default parameter, in case the caller wants to overwrite it (e.g. group or message)
            var trackingParameter = event.defaultParameters.merging(parameters) { (defaultParameter, _) -> Any in
                defaultParameter
            }
            trackingParameter[ParameterKey.timestamp.rawValue] = systemClock.now()

            tracker?.trackEvent(String(describing: event), parameters: trackingParameter, loglevel: loglevel)
        }
    }
}

internal func HSMTrack(_ event: TrackingEvent, parameters: [String: Any] = [:], loglevel: LogLevel) {
    TrackingManager.shared.track(event, parameters: parameters, loglevel: loglevel)
}
