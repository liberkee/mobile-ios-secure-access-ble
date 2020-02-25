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

    case bluetoothPoweredON
    case bluetoothPoweredOFF
    case bluetoothUnauthorized
    case bluetoothUnsupported
    
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
    case connectionFailed

    case serviceGrantRequested
    case serviceGrantRequestFailed
    case serviceGrantResponseReceived

    private var group: String {
        switch self {
        case .interfaceInitialized:
            return "Setup"
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
             .connectionDisconnected,
             .connectionFailed:
            return "Connection"
        case .serviceGrantRequested,
             .serviceGrantRequestFailed,
             .serviceGrantResponseReceived:
            return "ServiceGrant"
        case .bluetoothPoweredON,
             .bluetoothPoweredOFF,
             .bluetoothUnsupported,
             .bluetoothUnauthorized:
            return "Bluetooth"
        }
    }

    private var message: String {
        switch self {
        case .interfaceInitialized:
            return "Interface initialized"
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
        case .connectionFailed:
            return "Connection failed"
        case .serviceGrantRequested:
            return "Service grant is requested"
        case .serviceGrantRequestFailed:
            return "Failure in requesting service grant"
        case .serviceGrantResponseReceived:
            return "Service grant response is received"
        case .bluetoothPoweredON:
            return "Bluetooth is powered on"
        case .bluetoothPoweredOFF:
            return "Bluetooth is powered off"
        case .bluetoothUnauthorized:
            return "Bluetooth is unauthorized"
        case .bluetoothUnsupported:
            return "Bluetooth is unsupported"
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
