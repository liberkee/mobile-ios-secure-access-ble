//
//  SorcManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// Defines what a manager of SORCs provides
protocol SorcManagerType {

    // MARK: - Interface

    /// The bluetooth enabled status
    var isBluetoothEnabled: BehaviorSubject<Bool> { get }

    // MARK: - Discovery

    /// The state of SORC discovery with the action that led to this state
    var discoveryChange: ChangeSubject<DiscoveryChange> { get }

    // MARK: - Connection

    /// The state of the connection with the action that led to this state
    var connectionChange: ChangeSubject<ConnectionChange> { get }

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

    // MARK: - Service

    /// A service grant result was received
    var serviceGrantResultReceived: PublishSubject<ServiceGrantResult> { get }

    /**
     Requests a service grant from the connected SORC

     - parameter serviceGrantID: The ID the of the service grant
     */
    func requestServiceGrant(_ serviceGrantID: ServiceGrantID)
}
