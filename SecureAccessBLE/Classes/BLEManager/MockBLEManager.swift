//
//  MockBLEManager.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 26.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

class MockBLEManager: BLEManagerType {

    public var heartbeatInterval: Double = 2000.0

    public var heartbeatTimeout: Double = 4000.0

    public var connectedToSorc = PublishSubject<SID>()

    public var failedConnectingToSorc = PublishSubject<(sorc: SID, error: Error?)>()

    public var receivedServiceGrantTriggerForStatus = PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)>()

    public var sorcDiscovered = PublishSubject<SID>()

    public var sorcsLost = PublishSubject<[SID]>()

    public var blobOutdated = PublishSubject<()>()

    public var connected = BehaviorSubject<Bool>(value: false)

    public var updatedState = PublishSubject<()>()

    // TODO: PLAM-749 implement
    public var discoveredSorcs = BehaviorSubject<[SID]>(value: [])

    public var isPoweredOn: Bool {
        return true
    }

    public var isConnected: Bool {
        return true
    }

    public func hasSorcId(_: String) -> Bool {
        return true
    }

    public func connectToSorc(leaseToken _: LeaseToken, leaseTokenBlob _: LeaseTokenBlob) {
    }

    public func disconnect() {
    }

    public func sendServiceGrantForFeature(_: ServiceGrantFeature) {
    }
}
