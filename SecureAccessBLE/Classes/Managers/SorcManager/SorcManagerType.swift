//
//  SorcManagerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

/// The ID to identify a specific SORC
public typealias SorcID = UUID

/// Defines what a manager of SORCs provides
public protocol SorcManagerType {
    // MARK: - BLE Interface

    /// The bluetooth  state
    var bluetoothState: StateSignal<BluetoothState> { get }

    // MARK: - Discovery

    /// The state of SORC discovery with the action that led to this state
    var discoveryChange: ChangeSignal<DiscoveryChange> { get }

    /// Starts discovery for specific SORC with optional timeout. If timeout is not provided, default timeout will be used.
    /// The manager will finish either with `discovered(sorcID: SorcID)` followed by `stopDiscovery` action in success case
    /// or with a `discoveryFailed` if the SORC won't be found within timeout.
    /// - Parameters:
    ///   - sorcID: sorcID of interest
    ///   - timeout: timeout for discovery
    func startDiscovery(sorcID: SorcID, timeout: TimeInterval?)

    /// Starts discovery without specifying the `SorcID`.
    /// The manager will notify `discovered(sorcID: SorcID)`, `rediscovered(sorcID: SorcID)` or `lost(sorcIDs: Set<SorcID>)`
    /// actions for every scanned device until the discovery is stopped manually.
    ///
    /// Note: It is recommended to use `startDiscovery(sorcID: SorcID, timeout: TimeInterval?)` to
    /// search for specific `SorcID`.
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

    /// :nodoc:
    func registerInterceptor(_ interceptor: SorcInterceptor)
}
