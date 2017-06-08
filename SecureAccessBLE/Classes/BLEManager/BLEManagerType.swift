//
//  BLEManagerType.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 24.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Declares the contract a BLEManagerType has to follow
public protocol BLEManagerType: class {

    // MARK: - Configuration

    /// The interval a heartbeat is sent to the SORC
    var heartbeatInterval: Double { get set }

    /// The duration to wait for a heartbeat response from the SORC
    var heartbeatTimeout: Double { get set }

    // MARK: - Interface

    /// The bluetoothEnabled status
    var isBluetoothEnabled: BehaviorSubject<Bool> { get }

    // MARK: - Discovery

    /// If the SORC is discovered
    func hasSorcId(_ sorcId: String) -> Bool

    /// A SORC was discovered
    var sorcDiscovered: PublishSubject<SID> { get }

    /// SORCs were lost
    var sorcsLost: PublishSubject<[SID]> { get }

    // MARK: - Connection

    /// The state of the connection with the action that led to this state
    var connectionChange: BehaviorSubject<ConnectionChange> { get }

    // MARK: - Service

    /// A service grant trigger was received
    var receivedServiceGrantTriggerForStatus: PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)> { get }

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
