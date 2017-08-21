//
//  MockBLEManager.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 26.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Mocks the communication with a BLE device
class MockBLEManager: BLEManagerType {

    // MARK: - Configuration

    public let connectionTimeSeconds = 2
    public let serviceTimeSeconds = 2

    // Unused
    public var heartbeatInterval: Double = 2000.0

    // Unused
    public var heartbeatTimeout: Double = 4000.0

    // MARK: - Interface

    public var isBluetoothEnabled = BehaviorSubject(value: true)

    // MARK: - Discovery

    public func hasSorcId(_: SorcID) -> Bool {
        return true
    }

    // Not mocked
    public var sorcDiscovered = PublishSubject<SorcID>()

    // Not mocked
    public var sorcsLost = PublishSubject<[SorcID]>()

    // MARK: - Connection

    public var connectionChange = BehaviorSubject(value: ConnectionChange(state: .disconnected, action: .initial))

    // MARK: - Service

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: - Private properties

    private var discoveryWorkItem: DispatchWorkItem?
    private var connectWorkItem: DispatchWorkItem?
    private var serviceWorkItem: DispatchWorkItem?
    private var carIsLocked = true
    private var ignitionDisabled = true

    // MARK: - Actions

    public func startDiscovery() {}

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob _: LeaseTokenBlob) {
        let sorcId = leaseToken.sorcId
        connectionChange.onNext(ConnectionChange(state: .connecting(sorcId: sorcId), action: .connect))
        let connectWorkItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.connectionChange.onNext(ConnectionChange(
                state: .connected(sorcId: sorcId),
                action: .connectionEstablished(sorcId: sorcId, rssi: 0))
            )
        }
        self.connectWorkItem = connectWorkItem

        let connectDeadline = DispatchTime.now() + DispatchTimeInterval.seconds(connectionTimeSeconds)
        DispatchQueue.main.asyncAfter(deadline: connectDeadline, execute: connectWorkItem)
    }

    public func disconnect() {
        connectWorkItem?.cancel()
        connectWorkItem = nil
        serviceWorkItem?.cancel()
        serviceWorkItem = nil
        connectionChange.onNext(ConnectionChange(state: .disconnected, action: .disconnect))
    }

    public func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        let deadline = DispatchTime.now() + DispatchTimeInterval.seconds(serviceTimeSeconds)

        let workItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }

            let triggerStatus: ServiceGrantTriggerStatus
            switch feature {
            case .open:
                strongSelf.carIsLocked = false
                triggerStatus = .unlockSuccess
            case .close:
                strongSelf.carIsLocked = true
                triggerStatus = .lockSuccess
            case .ignitionStart:
                strongSelf.ignitionDisabled = false
                triggerStatus = .enableIgnitionSuccess
            case .ignitionStop:
                strongSelf.ignitionDisabled = true
                triggerStatus = .disableIgnitionSuccess
            case .lockStatus:
                triggerStatus = strongSelf.carIsLocked ? .lockStatusLocked : .lockStatusUnlocked
            case .ignitionStatus:
                triggerStatus = strongSelf.ignitionDisabled ? .ignitionStatusDisabled : .ignitionStatusEnabled
            }
            strongSelf.receivedServiceGrantTriggerForStatus.onNext((status: triggerStatus, error: nil))
        }

        DispatchQueue.main.asyncAfter(deadline: deadline, execute: workItem)
        serviceWorkItem = workItem
    }
}
