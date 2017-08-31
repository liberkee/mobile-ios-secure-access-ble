//
//  SorcManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

class SorcManager: SorcManagerType {

    private let bluetoothStatusProvider: BluetoothStatusProviderType
    private let scanner: ScannerType
    private let sessionManager: SessionManagerType

    var isBluetoothEnabled: BehaviorSubject<Bool> {
        return bluetoothStatusProvider.isBluetoothEnabled
    }

    var discoveryChange: ChangeSubject<DiscoveryChange> {
        return scanner.discoveryChange
    }

    var connectionChange: ChangeSubject<ConnectionChange> {
        return sessionManager.connectionChange
    }

    var serviceGrantResultReceived: PublishSubject<ServiceGrantResult> {
        return sessionManager.serviceGrantResultReceived
    }

    convenience init() {
        let connectionManager = ConnectionManager()
        let transportManager = TransportManager(connectionManager: connectionManager)
        let securityManager = SecurityManager(transportManager: transportManager)
        let sessionManager = SessionManager(securityManager: securityManager)

        self.init(
            bluetoothStatusProvider: connectionManager,
            scanner: connectionManager,
            sessionManager: sessionManager
        )
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

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        sessionManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    func disconnect() {
        sessionManager.disconnect()
    }

    func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        sessionManager.requestServiceGrant(serviceGrantID)
    }
}
