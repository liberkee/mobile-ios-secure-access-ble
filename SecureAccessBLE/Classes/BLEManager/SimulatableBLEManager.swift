//
//  SimulatableBLEManager.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 26.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// A BLEManager that can switch between simulated and real BLE communication
public class SimulatableBLEManager: BLEManagerType {

    /// The single shared instance
    public static let shared = SimulatableBLEManager(
        realManager: BLEManager.shared,
        mockManager: MockBLEManager()
    )

    private let realManager: BLEManagerType
    private let mockManager: BLEManagerType

    private var disposeBag: DisposeBag?

    private var currentManager: BLEManagerType {
        return isSimulating ? mockManager : realManager
    }

    /**
     Initializes the manager
     - parameter realManager: The manager for real BLE communication
     - parameter mockManager: The manager for simulated BLE communication
     */
    init(realManager: BLEManagerType, mockManager: BLEManagerType) {
        self.realManager = realManager
        self.mockManager = mockManager
    }

    // MARK: - Configuration

    /// If BLE is simulated currently
    public var isSimulating: Bool = false {
        willSet {
            currentManager.disconnect()
            disposeBag = nil
        }
        didSet {
            setUpManager(currentManager)
        }
    }

    public var heartbeatInterval: Double {
        get {
            return currentManager.heartbeatInterval
        }
        set {
            realManager.heartbeatInterval = newValue
            mockManager.heartbeatInterval = newValue
        }
    }

    public var heartbeatTimeout: Double {
        get {
            return currentManager.heartbeatTimeout
        }
        set {
            realManager.heartbeatTimeout = newValue
            mockManager.heartbeatTimeout = newValue
        }
    }

    // MARK: - Interface

    public var isBluetoothEnabled = BehaviorSubject<Bool>(value: false)

    // MARK: - Discovery

    public func hasSorcId(_ sorcId: SorcID) -> Bool {
        return currentManager.hasSorcId(sorcId)
    }

    public var sorcDiscovered = PublishSubject<SorcID>()

    public var sorcsLost = PublishSubject<[SorcID]>()

    // MARK: - Connection

    public var connectionChange = BehaviorSubject(value: ConnectionChange(state: .disconnected, action: .initial))

    // MARK: - Service

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: - Actions

    public func startDiscovery() {
        currentManager.startDiscovery()
    }

    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        currentManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    public func disconnect() {
        currentManager.disconnect()
    }

    public func sendServiceGrantForFeature(_ feature: ServiceGrantFeature) {
        currentManager.sendServiceGrantForFeature(feature)
    }

    // MARK: - Private methods

    private func setUpManager(_ manager: BLEManagerType) {

        let disposeBag = DisposeBag()

        manager.isBluetoothEnabled.subscribeNext { [weak self] enabled in
            guard let strongSelf = self else { return }
            strongSelf.isBluetoothEnabled.onNext(enabled)
        }
        .disposed(by: disposeBag)

        manager.sorcDiscovered.subscribeNext { [weak self] sorcId in
            guard let strongSelf = self else { return }
            strongSelf.sorcDiscovered.onNext(sorcId)
        }
        .disposed(by: disposeBag)

        manager.sorcsLost.subscribeNext { [weak self] lostSorcIds in
            guard let strongSelf = self else { return }
            strongSelf.sorcsLost.onNext(lostSorcIds)
        }
        .disposed(by: disposeBag)

        manager.connectionChange.subscribeNext { [weak self] change in
            guard let strongSelf = self else { return }
            strongSelf.connectionChange.onNext(change)
        }
        .disposed(by: disposeBag)

        manager.receivedServiceGrantTriggerForStatus.subscribeNext { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.receivedServiceGrantTriggerForStatus.onNext(result)
        }
        .disposed(by: disposeBag)

        self.disposeBag = disposeBag
    }
}
