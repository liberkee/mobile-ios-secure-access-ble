//
//  Dependencies.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CoreBluetooth

class Dependencies {

    static let shared = Dependencies()

    func makeSorcManager() -> SorcManager {
        let centralManager = CBCentralManager(delegate: nil, queue: nil,
                                              options: [CBPeripheralManagerOptionShowPowerAlertKey: 0])
        let systemClock = SystemClock()

        let createTimer: ConnectionManager.CreateTimer = { block in
            /// The interval a timer is triggered to remove outdated discovered SORCs
            let removeOutdatedSorcsTimerIntervalSeconds: Double = 2
            return Timer(timeInterval: removeOutdatedSorcsTimerIntervalSeconds, repeats: true, block: { _ in block() })
        }

        let appActivityStatusProvider = AppActivityStatusProvider(notificationCenter: NotificationCenter.default)

        let connectionManager = ConnectionManager(
            centralManager: centralManager,
            systemClock: systemClock,
            createTimer: createTimer,
            appActivityStatusProvider: appActivityStatusProvider
        )

        let transportManager = TransportManager(connectionManager: connectionManager)
        let securityManager = SecurityManager(transportManager: transportManager)
        let sessionManager = SessionManager(securityManager: securityManager)

        return SorcManager(
            bluetoothStatusProvider: connectionManager,
            scanner: connectionManager,
            sessionManager: sessionManager
        )
    }
}
