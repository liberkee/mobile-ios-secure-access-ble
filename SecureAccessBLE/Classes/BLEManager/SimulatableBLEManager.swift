//
//  SimulatableBLEManager.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 26.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// A BLEManager that can switch between simulated and real BLE communication
public class SimulatableBLEManager: BLEManagerType {

    /// The single shared instance
    public static let shared = SimulatableBLEManager(
        realManager: BLEManager.shared,
        mockManager: MockBLEManager()
    )

    private let realManager: BLEManagerType
    private let mockManager: BLEManagerType

    private let disposeBag = DisposeBag()

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

        setUpManager(self.realManager)
        setUpManager(self.mockManager)
    }

    /// If BLE is simulated currently
    public var isSimulating: Bool = false {
        willSet {
            currentManager.disconnect()
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

    public var connectedToSorc = PublishSubject<SID>()

    public var failedConnectingToSorc = PublishSubject<(sorc: SID, error: Error?)>()

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    public var sorcDiscovered = PublishSubject<SID>()

    public var sorcsLost = PublishSubject<[SID]>()

    public var blobOutdated = PublishSubject<()>()

    public var connected = BehaviorSubject<Bool>(value: false)

    public var updatedState = PublishSubject<()>()

    public var isPoweredOn: Bool {
        return currentManager.isPoweredOn
    }

    public func hasSorcId(_ sordId: String) -> Bool {
        return currentManager.hasSorcId(sordId)
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

        manager.connectedToSorc.subscribeNext { [weak self] sorc in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.connectedToSorc.onNext(sorc)
            }
        }
        .disposed(by: disposeBag)

        manager.failedConnectingToSorc.subscribeNext { [weak self] sorc in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.failedConnectingToSorc.onNext(sorc)
            }
        }
        .disposed(by: disposeBag)

        manager.receivedServiceGrantTriggerForStatus.subscribeNext { [weak self] result in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.receivedServiceGrantTriggerForStatus.onNext(result)
            }
        }
        .disposed(by: disposeBag)

        manager.sorcDiscovered.subscribeNext { [weak self] sorc in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.sorcDiscovered.onNext(sorc)
            }
        }
        .disposed(by: disposeBag)

        manager.sorcsLost.subscribeNext { [weak self] lostSorcs in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.sorcsLost.onNext(lostSorcs)
            }
        }
        .disposed(by: disposeBag)

        manager.blobOutdated.subscribeNext { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.blobOutdated.onNext()
            }
        }
        .disposed(by: disposeBag)

        manager.connected.subscribeNext { [weak self] connected in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.connected.onNext(connected)
            }
        }
        .disposed(by: disposeBag)

        manager.updatedState.subscribeNext { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.currentManager === manager {
                strongSelf.updatedState.onNext()
            }
        }
        .disposed(by: disposeBag)
    }
}
