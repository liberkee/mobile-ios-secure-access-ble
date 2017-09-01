//
//  BLEManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Only lowercased IDs with hyphens are supported
public typealias SorcID = String

/// Declares the contract a BLEManagerType has to follow
public protocol BLEManagerType: class {

    // MARK: - Configuration

    /// The interval a heartbeat is sent to the SORC
    var heartbeatInterval: Double { get set }

    /// The duration to wait for a heartbeat response from the SORC
    var heartbeatTimeout: Double { get set }

    // MARK: - Interface

    /// The bluetoothEnabled status
    var isBluetoothEnabled: StateSignal<Bool> { get }

    // MARK: - Discovery

    /// The state of SORC discovery with the action that led to this state
    var discoveryChange: ChangeSignal<DiscoveryChange> { get }

    // MARK: - Connection

    /// The state of the connection with the action that led to this state
    var connectionChange: ChangeSignal<ConnectionChange> { get }

    // MARK: - Service

    /// A service grant trigger was received
    var receivedServiceGrantTriggerForStatus: EventSignal<(status: ServiceGrantTriggerStatus?, error: String?)> { get }

    // MARK: - Actions

    /**
     Connects to a SORC

     - parameter leaseToken: The lease token for the SORC
     - parameter leaseTokenBlob: The blob for the SORC
     */
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)

    /**
     Disconnects from current SORC
     */
    func disconnect()

    /**
     Send service grant for a feature to the current connected device

     - parameter feature: The feature to send the service grant for
     */
    func sendServiceGrantForFeature(_ feature: ServiceGrantFeature)
}
