//
//  MockBLEManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

public protocol DiscoveredSorcsProviderType {
    var discoveredSorcInfos: BehaviorSubject<[SorcID: SorcInfo]> { get }
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

    public var isBluetoothEnabled: StateSignal<Bool> {
        return isBluetoothEnabledSubject.asSignal()
    }

    private let isBluetoothEnabledSubject = BehaviorSubject(value: true)

    // MARK: - Discovery

    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return discoveryChangeSubject.asSignal()
    }

    private let discoveryChangeSubject = ChangeSubject<DiscoveryChange>(state: [:])

    // MARK: - Connection

    public var connectionChange: ChangeSignal<ConnectionChange> {
        return connectionChangeSubject.asSignal()
    }

    private let connectionChangeSubject = ChangeSubject<ConnectionChange>(state: .disconnected)

    // MARK: - Service

    public var receivedServiceGrantTriggerForStatus: EventSignal<(status: ServiceGrantTriggerStatus?, error: String?)> {
        return receivedServiceGrantTriggerForStatusSubject.asSignal()
    }

    private let receivedServiceGrantTriggerForStatusSubject = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

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
        discoveredSorcsProvider.discoveredSorcInfos.subscribeNext { [weak self] sorcInfos in
            self?.discoveryChangeSubject.onNext(.init(state: sorcInfos, action: .initial))
        }
        .disposed(by: disposeBag)
    }

    // MARK: - Actions

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob _: LeaseTokenBlob) {
        let sorcID = leaseToken.sorcID
        connectionChangeSubject.onNext(ConnectionChange(state: .connecting(sorcID: sorcID, state: .physical),
                                                        action: .connect(sorcID: sorcID)))
        let connectWorkItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.connectionChangeSubject.onNext(ConnectionChange(
                state: .connected(sorcID: sorcID),
                action: .connectionEstablished(sorcID: sorcID))
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
        connectionChangeSubject.onNext(ConnectionChange(state: .disconnected, action: .disconnect))
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
            strongSelf.receivedServiceGrantTriggerForStatusSubject.onNext((status: triggerStatus, error: nil))
        }

        DispatchQueue.main.asyncAfter(deadline: deadline, execute: workItem)
        serviceWorkItem = workItem
    }
}
