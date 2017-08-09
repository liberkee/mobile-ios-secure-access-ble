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
    private static var shared: SimulatableBLEManager!
    public static func shared(discoveredSorcsProvider: DiscoveredSorcsProviderType) -> SimulatableBLEManager {
        if shared == nil {
            shared = SimulatableBLEManager(
                realManager: BLEManager.shared,
                mockManager: MockBLEManager(discoveredSorcsProvider: discoveredSorcsProvider)
            )
        }
        return shared
    }

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

    public let isBluetoothEnabled = BehaviorSubject<Bool>(value: false)

    // MARK: - Discovery

    public let discoveryChange = ChangeSubject<DiscoveryChange>(state: Set<SorcID>())

    // MARK: - Connection

    public let connectionChange = BehaviorSubject(value: ConnectionChange(state: .disconnected, action: .initial))

    // MARK: - Service

    public let receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: - Actions

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
            self?.isBluetoothEnabled.onNext(enabled)
        }
        .disposed(by: disposeBag)

        manager.discoveryChange.subscribeNext { [weak self] change in
            self?.discoveryChange.onNext(change)
        }
        .disposed(by: disposeBag)

        manager.connectionChange.subscribeNext { [weak self] change in
            self?.connectionChange.onNext(change)
        }
        .disposed(by: disposeBag)

        manager.receivedServiceGrantTriggerForStatus.subscribeNext { [weak self] result in
            self?.receivedServiceGrantTriggerForStatus.onNext(result)
        }
        .disposed(by: disposeBag)

        self.disposeBag = disposeBag
    }
}
