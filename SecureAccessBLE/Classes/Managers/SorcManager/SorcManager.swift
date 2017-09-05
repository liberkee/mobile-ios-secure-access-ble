//
//  SorcManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

public class SorcManager: SorcManagerType {

    public static func make() -> SorcManager {
        return Dependencies.shared.makeSorcManager()
    }

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

    public var serviceGrantResultReceived: EventSignal<ServiceGrantResult> {
        return sessionManager.serviceGrantResultReceived.asSignal()
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
        scanner.startDiscovery()
    }

    public func stopDiscovery() {
        scanner.stopDiscovery()
    }

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sessionManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    public func disconnect() {
        sessionManager.disconnect()
    }

    public func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        sessionManager.requestServiceGrant(serviceGrantID)
    }
}
