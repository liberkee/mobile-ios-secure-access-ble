//
//  TrackingEvent.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 06.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

internal enum TrackingEvent: String {
    case interfaceInitialized

    case discoveryStartedByApp
    case discoveryStarted
    case discoveryCancelledbyApp
    case discoveryStopped
    /// discovered sorc, params should contain discovered sorcID
    case discoverySorcDiscovered
    /// lost previously discovered sorcs, sorcIDs should be in params
    case discoveryLost

    case connectionStartedByApp
    case connectionStarted
    case connectionTransferringBLOB
    case connectionEstablished
    case connectionCancelledByApp
    case connectionDisconnected

    case serviceGrantRequested
    case serviceGrantRequestFailed
    case serviceGrantResponseReceived

    private var group: String {
        switch self {
        case .interfaceInitialized:
            return "Library Setup"
        case .discoveryStartedByApp,
             .discoveryStarted,
             .discoveryCancelledbyApp,
             .discoveryStopped,
             .discoverySorcDiscovered,
             .discoveryLost:
            return "Discovery"
        case .connectionStartedByApp,
             .connectionStarted,
             .connectionTransferringBLOB,
             .connectionEstablished,
             .connectionCancelledByApp,
             .connectionDisconnected:
            return "Connection"
        case .serviceGrantRequested,
             .serviceGrantRequestFailed,
             .serviceGrantResponseReceived:
            return "ServiceGrant"
        }
    }

    private var message: String {
        switch self {
        case .interfaceInitialized:
            return "Information regarding initialization interface"
        case .discoveryStartedByApp:
            return "Discovery was started by App"
        case .discoveryStarted:
            return "Discovery was started"
        case .discoveryCancelledbyApp:
            return "Discovery was cancelled by App"
        case .discoveryStopped:
            return "Discovery was stopped"
        case .discoverySorcDiscovered:
            return "Discovered sorc"
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
        case .serviceGrantRequested:
            return "Service grant is requested"
        case .serviceGrantRequestFailed:
            return "Failure in requesting service grant"
        case .serviceGrantResponseReceived:
            return "Service grant response is received"
        }
    }

    var shouldBeReportedToTacs: Bool {
        return [TrackingEvent.connectionTransferringBLOB].contains(self)
    }

    var defaultParameters: [String: Any] {
        return [
            ParameterKey.group.rawValue: group,
            ParameterKey.message.rawValue: message
        ]
    }
}
