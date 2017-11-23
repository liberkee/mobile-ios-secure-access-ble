//
//  SorcManager.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

public class SorcManager: SorcManagerType {

    private let bluetoothStatusProvider: BluetoothStatusProviderType
    private let scanner: ScannerType
    private let sessionManager: SessionManagerType

    public var isBluetoothEnabled: StateSignal<Bool> {
        return bluetoothStatusProvider.isBluetoothEnabled.asSignal()
    }

    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return scanner.discoveryChange.asSignal()
    }

    public var connectionChange: ChangeSignal<ConnectionChange> {
        return sessionManager.connectionChange.asSignal()
    }

    public var serviceGrantChange: ChangeSignal<ServiceGrantChange> {
        return sessionManager.serviceGrantChange.asSignal()
    }

    init(
        bluetoothStatusProvider: BluetoothStatusProviderType,
        scanner: ScannerType,
        sessionManager: SessionManagerType
    ) {
        self.bluetoothStatusProvider = bluetoothStatusProvider
        self.scanner = scanner
        self.sessionManager = sessionManager
    }

    public func startDiscovery() {
        HSMLog(message: "BLE - Scanner started discovery", level: .verbose)
        scanner.startDiscovery()
    }

    public func stopDiscovery() {
        HSMLog(message: "BLE - Scanner stopped discovery", level: .verbose)
        scanner.stopDiscovery()
    }

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        HSMLog(message: "BLE - Connected to SORC", level: .verbose)
        sessionManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    public func disconnect() {
        HSMLog(message: "BLE - Disconnected", level: .verbose)
        sessionManager.disconnect()
    }

    public func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        HSMLog(message: "BLE - Request service grant", level: .verbose)
        sessionManager.requestServiceGrant(serviceGrantID)
    }
}

extension SorcManager {

    /// Initializes a `SorcManager`. After initialization keep a strong reference to this instance as long as you need it.
    ///
    /// Note: Only use one instance at a time.
    public convenience init(configuration: SorcManager.Configuration = SorcManager.Configuration()) {

        // ConnectionManager

        let connectionConfiguration = ConnectionManager.Configuration(
            serviceID: configuration.serviceID,
            notifyCharacteristicID: configuration.notifyCharacteristicID,
            writeCharacteristicID: configuration.writeCharacteristicID,
            sorcOutdatedDuration: configuration.sorcOutdatedDuration,
            removeOutdatedSorcsInterval: configuration.removeOutdatedSorcsInterval
        )
        let connectionManager = ConnectionManager(configuration: connectionConfiguration)

        // TransportManager

        let transportManager = TransportManager(connectionManager: connectionManager)

        // SecurityManager

        let securityManager = SecurityManager(transportManager: transportManager)

        // SessionManager

        let sessionConfiguration = SessionManager.Configuration(
            heartbeatInterval: configuration.heartbeatInterval,
            heartbeatTimeout: configuration.heartbeatTimeout,
            maximumEnqueuedMessages: configuration.maximumEnqueuedMessages
        )
        let sessionManager = SessionManager(securityManager: securityManager, configuration: sessionConfiguration)

        // SorcManager

        self.init(
            bluetoothStatusProvider: connectionManager,
            scanner: connectionManager,
            sessionManager: sessionManager
        )
    }
}
