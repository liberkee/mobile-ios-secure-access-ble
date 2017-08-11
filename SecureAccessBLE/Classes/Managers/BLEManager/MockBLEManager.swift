//
//  MockBLEManager.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 26.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

public protocol DiscoveredSorcsProviderType {
    var discoveredSorcIDs: BehaviorSubject<[SorcID: SorcInfo]> { get }
}

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

    public let isBluetoothEnabled = BehaviorSubject(value: true)

    // MARK: - Discovery

    public let discoveryChange = ChangeSubject<DiscoveryChange>(state: [:])

    // MARK: - Connection

    public let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    // MARK: - Service

    public let receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: - Private properties

    private let discoveredSorcsProvider: DiscoveredSorcsProviderType
    private let disposeBag = DisposeBag()

    private var discoveryWorkItem: DispatchWorkItem?
    private var connectWorkItem: DispatchWorkItem?
    private var serviceWorkItem: DispatchWorkItem?
    private var carIsLocked = true
    private var ignitionDisabled = true

    init(discoveredSorcsProvider: DiscoveredSorcsProviderType) {
        self.discoveredSorcsProvider = discoveredSorcsProvider
        discoveredSorcsProvider.discoveredSorcIDs.subscribeNext { [weak self] sorcIDs in
            self?.discoveryChange.onNext(.init(state: sorcIDs, action: .initial))
        }
        .disposed(by: disposeBag)
    }

    // MARK: - Actions

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob _: LeaseTokenBlob) {
        let sorcID = leaseToken.sorcID
        connectionChange.onNext(ConnectionChange(state: .connecting(sorcID: sorcID), action: .connect))
        let connectWorkItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.connectionChange.onNext(ConnectionChange(
                state: .connected(sorcID: sorcID),
                action: .connectionEstablished(sorcID: sorcID, rssi: 0))
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
