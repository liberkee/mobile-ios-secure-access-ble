// TACSManager.swift
// TACS

// Created on 08.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.


import Foundation

import SecureAccessBLE

class TACSManager {
    private let sorcManager: SorcManagerType
    
    public let telematicsManager: TelematicsManagerType
    public let vehicleAccessManager: VehicleAccessManagerType
    
    // MARK: - BLE Interface
    
    /// The bluetooth enabled status
    public var isBluetoothEnabled: StateSignal<Bool> {
        return sorcManager.isBluetoothEnabled
    }
    
    // MARK: - Discovery
    
    /// Starts discovery of SORCs
    public func startDiscovery() {
        sorcManager.startDiscovery()
    }
    
    /// Stops discovery of SORCs
    public func stopDiscovery() {
        sorcManager.stopDiscovery()
    }
    
    /// The state of SORC discovery with the action that led to this state
    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return sorcManager.discoveryChange
    }
    
    // MARK: - Connection
    
    /// The state of the connection with the action that led to this state
    public var connectionChange: ChangeSignal<ConnectionChange> {
        return sorcManager.connectionChange
    }
    
    /// Connects to a SORC
    ///
    /// - Parameters:
    ///   - leaseToken: The lease token for the SORC
    ///   - leaseTokenBlob: The blob for the SORC
    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sorcManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }
    
    /**
     Disconnects from current SORC
     */
    public func disconnect() {
        sorcManager.disconnect()
    }
    
    init(sorcManager: SorcManagerType,
         telematicsManager: TelematicsManagerType,
         vehicleAccessManager: VehicleAccessManagerType) {
        self.sorcManager = sorcManager
        self.telematicsManager = telematicsManager
        self.vehicleAccessManager = vehicleAccessManager
        self.sorcManager.registerInterceptor(telematicsManager)
        self.sorcManager.registerInterceptor(vehicleAccessManager)
    }
}
