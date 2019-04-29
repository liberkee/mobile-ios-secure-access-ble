// TACSManager.swift
// TACS

// Created on 08.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.


import Foundation

import SecureAccessBLE

public class TACSManager {
    private let internalSorcManager: SorcManagerType
    @available(*, deprecated: 1.0, message: "Use VehicleAccessManager or TelematicsManager instead.")
    public var sorcManager: SorcManagerType { return internalSorcManager }
    
    public let telematicsManager: TelematicsManagerType
    public let vehicleAccessManager: VehicleAccessManagerType
    
    // MARK: - BLE Interface
    
    /// The bluetooth enabled status
    public var isBluetoothEnabled: StateSignal<Bool> {
        return internalSorcManager.isBluetoothEnabled
    }
    
    // MARK: - Discovery
    
    /// Starts discovery of SORCs
    public func startDiscovery() {
        internalSorcManager.startDiscovery()
    }
    
    /// Stops discovery of SORCs
    public func stopDiscovery() {
        internalSorcManager.stopDiscovery()
    }
    
    /// The state of SORC discovery with the action that led to this state
    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return internalSorcManager.discoveryChange
    }
    
    // MARK: - Connection
    
    /// The state of the connection with the action that led to this state
    public var connectionChange: ChangeSignal<ConnectionChange> {
        return internalSorcManager.connectionChange
    }
    
    /// Connects to a SORC
    ///
    /// - Parameters:
    ///   - leaseToken: The lease token for the SORC
    ///   - leaseTokenBlob: The blob for the SORC
    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        internalSorcManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }
    
    /**
     Disconnects from current SORC
     */
    public func disconnect() {
        internalSorcManager.disconnect()
    }
    
    init(sorcManager: SorcManagerType,
         telematicsManager: TelematicsManagerType,
         vehicleAccessManager: VehicleAccessManagerType) {
        self.internalSorcManager = sorcManager
        self.telematicsManager = telematicsManager
        self.vehicleAccessManager = vehicleAccessManager
        self.internalSorcManager.registerInterceptor(telematicsManager)
        self.internalSorcManager.registerInterceptor(vehicleAccessManager)
    }
    
    public convenience init() {
        //TODO: Provide configuration!
        let sorcManager = SorcManager()
        let telematicsManager = TelematicsManager(sorcManager: sorcManager)
        let vehicleAccessManager = VehicleAccessManager(sorcManager: sorcManager)
        self.init(sorcManager: sorcManager,
                  telematicsManager: telematicsManager,
                  vehicleAccessManager: vehicleAccessManager)
    }
}
