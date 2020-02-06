//
//  SATracker.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 06.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public protocol TrackEventType: CustomStringConvertible {
    func groupID() -> String
    func messageOfEvent() -> String
}

internal enum SAEvent: String, TrackEventType {
    var description: String {
        return rawValue
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
    case discoverySuccessfull
    case discoveryLost

    case connectionStartedByApp
    case connectionStarted
    case connectionTransferringBLOB
    case connectionEstablished
    case connectionCancelledByApp
    case connectionDisconnected

    var group: String {
        switch self {
        case .discoveryStartedByApp,
             .discoveryStarted,
             .discoveryCancelledbyApp,
             .discoveryStopped,
             .discoverySuccessfull,
             .discoveryLost:
            return "Discovery"
        case .connectionStartedByApp,
             .connectionStarted,
             .connectionTransferringBLOB,
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
            return "Discovery was cancelled by App"
        case .discoveryStopped:
            return "Discovery was stopped"
        case .discoverySuccessfull:
            return "Discovery was completed successfully"
        case .discoveryLost:
            return "Discovery was lost"
        case .connectionStartedByApp:
            return "Connection request by App"
        case .connectionStarted:
            return "Connection request"
        case .connectionTransferringBLOB:
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
