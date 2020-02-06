//
//  EventTrackManager.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 31.01.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//
//
// import Foundation
//
// public protocol EventTracker {
//    func trackEvents(_ events: String, parameter: [String: Any])
// }
//
// public struct DiscoverVehicle {
//    public enum event: String {
//        case discoveryStartedByApp
//        case discoveryStarted
//        case discoveryCancelledbyApp
//        case discoveryStopped
//        case discoverySuccessful
//        case discoveryLost
//    }
// }
//
// public struct Setup {
//    public enum event: String {
//        case interfaceInitialized
//        case accessGrantAccepted
//        case accessGrantRejected
//    }
// }
//
// public struct Connection {
//    public enum event: String {
//        case connectionStartedByApp
//        case connectionStarted
//        case connectionTranferringBLOB
//        case connectionEstablished
//        case connectionCancelledByApp
//        case connectionDisconnected
//    }
// }
//
// internal struct TrackingParameter {
//    internal enum group: String {
//        case scanBLE = "Scan BLE"
//        case connection = "Connection"
//        case request = "Request"
//        case response = "Response"
//    }
//
//    internal var message: String
//    internal var timeStamp: Date
//    internal var group: group
// }
//
////
// internal func HSMTracker(forEvent _: TrackingParameter.group, withMessage _: String, level _: LogLevel) {
////    EventTrackManager.shared.trackEvents(forEvent: group, withMessage: message, for: level)
// }

//
// public class EventTrackManager {
//    public var eventTracker: EventTracker?
//
//    public static let shared = EventTrackManager()
//
//    private var systemClock: SystemClockType = SystemClock()
//
//    internal var logLevel: String = {
//        LogLevel.info.toString()
//    }()
//
//    init() {}
//
//    internal func trackEvents(forEvent group: TrackingParameter.group, withMessage message: String, for level: LogLevel) {
//        if logLevel == level.toString() {
//            let parameter = ["message": message,
//                             "timeStamp": systemClock.now()] as [String: Any]
//            eventTracker?.trackEvents(group.rawValue, parameter: parameter)
//        }
//    }
// }
