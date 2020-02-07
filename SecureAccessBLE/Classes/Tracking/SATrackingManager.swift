//
//  SATrackingManager.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 04.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Protocol which describes the Tracker interface. Conform to this protocol in your tracker to receive the events.
public protocol SAEventTracker {
    func trackEvent(_ event: String, parameters: [String: Any], loglevel: LogLevel)
}

internal enum ParameterKey: String {
    // default parameters, present in every event
    case group
    case message
    case timestamp

    // additional data
    case sorcID
    case sorcIDs
    case error

    // generic payload data
    case data

    // system data
    case secureAccessFrameworkVersion
    case phoneModel
    case osVersion
    case os
}

/// Tracking manager to be used for registering tracker of type `SAEventTracker`.
public class SATrackingManager {
    private var tracker: SAEventTracker?

    private var logLevel: LogLevel = .info
    private let systemClock: SystemClockType
    
    /// Static (singleton) instance of the `SATrackingManager`
    public static var shared = SATrackingManager()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private var systemParameters: [String: Any] = [
        ParameterKey.os.rawValue: UIDevice.current.systemName,
        ParameterKey.osVersion.rawValue: UIDevice.current.systemVersion,
        ParameterKey.phoneModel.rawValue: UIDevice.current.name,
        ParameterKey.secureAccessFrameworkVersion.rawValue:
            Bundle(for: SATrackingManager.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    ]
    /// :nodoc
    // Set to true to filter out events which should not be reported to TACS Framework since it tracks them on its own
    public var usedByTACSSDK: Bool = false

    
    /// Registers tracker which will be used to pass events.
    /// - Parameters:
    ///   - tracker: the tracker
    ///   - logLevel: log level which can be used to filter events
    public func registerTracker(_ tracker: SAEventTracker, logLevel: LogLevel) {
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
            // Prefer system parameter to not allow overwriting them
            trackingParameter.merge(systemParameters) { (_, systemParameter) -> Any in
                systemParameter
            }
            trackingParameter[ParameterKey.timestamp.rawValue] = dateFormatter.string(from: systemClock.now())

            tracker?.trackEvent(String(describing: event), parameters: trackingParameter, loglevel: loglevel)
        }
    }
}

internal func HSMTrack(_ event: TrackingEvent, parameters: [String: Any] = [:], loglevel: LogLevel) {
    SATrackingManager.shared.track(event, parameters: parameters, loglevel: loglevel)
}
