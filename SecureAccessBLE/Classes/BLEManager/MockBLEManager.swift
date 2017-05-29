//
//  MockBLEManager.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 26.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

class MockBLEManager: BLEManagerType {

    // MARK: - Configuration

    public let connectionTimeSeconds = 17
    public let serviceTimeSeconds = 2

    public var heartbeatInterval: Double = 2000.0

    public var heartbeatTimeout: Double = 4000.0

    // MARK: - Interface

    public var isPoweredOn: Bool {
        return true
    }

    // Not mocked
    public var updatedState = PublishSubject<()>()

    // MARK: - Discovery

    // Not mocked
    public func hasSorcId(_: String) -> Bool {
        return false
    }

    // Not mocked
    public var sorcDiscovered = PublishSubject<SID>()

    // Not mocked
    public var sorcsLost = PublishSubject<[SID]>()

    // Not mocked
    public var discoveredSorcs = BehaviorSubject<[SID]>(value: [])

    // MARK: - Connection

    public var connected = BehaviorSubject<Bool>(value: false)

    // Not mocked
    public var connectedToSorc = PublishSubject<SID>()

    // Not mocked
    public var failedConnectingToSorc = PublishSubject<(sorc: SID, error: Error?)>()

    // Not mocked
    public var blobOutdated = PublishSubject<()>()

    // MARK: - Service

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    // MARK: - Private properties

    private var connectWorkItem: DispatchWorkItem?
    private var serviceWorkItem: DispatchWorkItem?
    private var carIsLocked = true
    private var ignitionDisabled = true

    // MARK: - Actions

    public func connectToSorc(leaseToken _: LeaseToken, leaseTokenBlob _: LeaseTokenBlob) {
        let deadline = DispatchTime.now() + DispatchTimeInterval.seconds(connectionTimeSeconds)
        let workItem = DispatchWorkItem { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.connected.onNext(true)
        }
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: workItem)
        connectWorkItem = workItem
    }

    public func disconnect() {
        connectWorkItem?.cancel()
        connectWorkItem = nil
        serviceWorkItem?.cancel()
        serviceWorkItem = nil
        connected.onNext(false)
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
