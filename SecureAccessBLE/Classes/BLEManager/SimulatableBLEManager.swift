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

    public func hasSorcId(_ sordId: String) -> Bool {
        return currentManager.hasSorcId(sordId)
    }

    public var sorcDiscovered = PublishSubject<SID>()

    public var sorcsLost = PublishSubject<[SID]>()

    // MARK: - Connection

    public var connected = BehaviorSubject<Bool>(value: false)

    public var connectedToSorc = PublishSubject<SID>()

    public var failedConnectingToSorc = PublishSubject<(sorc: SID, error: Error?)>()

    public var blobOutdated = PublishSubject<()>()

    // MARK: - Service

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

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

        manager.connectedToSorc.subscribeNext { [weak self] sorc in
            guard let strongSelf = self else { return }
            strongSelf.connectedToSorc.onNext(sorc)
        }
        .disposed(by: disposeBag)

        manager.failedConnectingToSorc.subscribeNext { [weak self] sorc in
            guard let strongSelf = self else { return }
            strongSelf.failedConnectingToSorc.onNext(sorc)
        }
        .disposed(by: disposeBag)

        manager.receivedServiceGrantTriggerForStatus.subscribeNext { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.receivedServiceGrantTriggerForStatus.onNext(result)
        }
        .disposed(by: disposeBag)

        manager.sorcDiscovered.subscribeNext { [weak self] sorc in
            guard let strongSelf = self else { return }
            strongSelf.sorcDiscovered.onNext(sorc)
        }
        .disposed(by: disposeBag)

        manager.sorcsLost.subscribeNext { [weak self] lostSorcs in
            guard let strongSelf = self else { return }
            strongSelf.sorcsLost.onNext(lostSorcs)
        }
        .disposed(by: disposeBag)

        manager.blobOutdated.subscribeNext { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.blobOutdated.onNext()
        }
        .disposed(by: disposeBag)

        manager.connected.subscribeNext { [weak self] connected in
            guard let strongSelf = self else { return }
            strongSelf.connected.onNext(connected)
        }
        .disposed(by: disposeBag)

        manager.isBluetoothEnabled.subscribeNext { [weak self] enabled in
            guard let strongSelf = self else { return }
            strongSelf.isBluetoothEnabled.onNext(enabled)
        }
        .disposed(by: disposeBag)

        self.disposeBag = disposeBag
    }
}
