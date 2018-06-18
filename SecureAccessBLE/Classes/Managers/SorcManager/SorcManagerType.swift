//
//  SorcManagerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// The ID to identify a specific SORC
public typealias SorcID = UUID

/// Defines what a manager of SORCs provides
public protocol SorcManagerType {

    // MARK: - BLE Interface

    /// The bluetooth enabled status
    var isBluetoothEnabled: StateSignal<Bool> { get }

    // MARK: - Discovery

    /// The state of SORC discovery with the action that led to this state
    var discoveryChange: ChangeSignal<DiscoveryChange> { get }

    /// Starts discovery of SORCs
    func startDiscovery()

    /// Stops discovery of SORCs
    func stopDiscovery()

    // MARK: - Connection

    /// The state of the connection with the action that led to this state
    var connectionChange: ChangeSignal<ConnectionChange> { get }

    /// Connects to a SORC
    ///
    /// - Parameters:
    ///   - leaseToken: The lease token for the SORC
    ///   - leaseTokenBlob: The blob for the SORC
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)

    /**
     Disconnects from current SORC
     */
    func disconnect()

    // MARK: - Service

    /// The state of service grant requesting with the action that led to this state
    var serviceGrantChange: ChangeSignal<ServiceGrantChange> { get }

    /**
     Requests a service grant from the connected SORC

     - Parameter serviceGrantID: The ID the of the service grant
     */
    func requestServiceGrant(_ serviceGrantID: ServiceGrantID)
}
