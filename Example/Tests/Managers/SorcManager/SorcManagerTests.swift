//
//  SorcManagerTests.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

@testable import SecureAccessBLE
import XCTest

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
private let sorcIDB = UUID(uuidString: "fd487104-c03b-4a94-8162-08826746b52d")!

private let serviceGrantIDA: UInt16 = 0x01

private class MockBluetoothStatusProvider: BluetoothStatusProviderType {
    let isBluetoothEnabled = BehaviorSubject<Bool>(value: false)
}

private class MockScanner: ScannerType {
    let discoveryChange = ChangeSubject<DiscoveryChange>(state: .init(
        discoveredSorcs: SorcInfos(),
        discoveryIsEnabled: false
    ))

    var startDiscoveryCalled = false
    func startDiscovery() {
        startDiscoveryCalled = true
    }

    var stopDiscoveryCalled = false
    func stopDiscovery() {
        stopDiscoveryCalled = true
    }
}

private class MockSessionManager: SessionManagerType {
    let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    var connectToSorcCalledWithArguments: (leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)?
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        connectToSorcCalledWithArguments = (leaseToken, leaseTokenBlob)
    }

    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }

    let serviceGrantChange = ChangeSubject<ServiceGrantChange>(state: ServiceGrantChange.State(requestingServiceGrantIDs: []))

    var requestServiceGrantCalledWithID: ServiceGrantID?
    func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        requestServiceGrantCalledWithID = serviceGrantID
    }
}

extension SorcInfo {
    static var stableTestInstance: SorcInfo {
        return .init(
            sorcID: sorcIDA,
            discoveryDate: .init(timeIntervalSince1970: 0),
            rssi: 0
        )
    }

    static var stableTestInstanceA: SorcInfo {
        return SorcInfo.stableTestInstance
    }

    static var stableTestInstanceB: SorcInfo {
        return .init(
            sorcID: sorcIDB,
            discoveryDate: .init(timeIntervalSince1970: 1),
            rssi: 0
        )
    }
}

class SorcManagerTests: XCTestCase {
    fileprivate var bluetoothStatusProvider = MockBluetoothStatusProvider()
    fileprivate var scanner = MockScanner()
    fileprivate var sessionManager = MockSessionManager()
    var sorcManager: SorcManager!

    override func setUp() {
        super.setUp()
        sorcManager = SorcManager(
            bluetoothStatusProvider: bluetoothStatusProvider,
            scanner: scanner,
            sessionManager: sessionManager
        )
    }

    func test_init_succeeds() {
        XCTAssertNotNil(sorcManager)
    }

    func test_convenienceInit_succeeds() {
        XCTAssertNotNil(SorcManager())
    }

    func test_isBluetoothEnabled_ifTrueIsProvided_isTrue() {
        // Given
        bluetoothStatusProvider.isBluetoothEnabled.onNext(true)

        // When
        let isEnabled = sorcManager.isBluetoothEnabled.state

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_isBluetoothEnabled_ifNewStatusIsProvided_itNotifiesNewStatus() {
        // Given
        var receivedStatus: Bool?
        _ = sorcManager.isBluetoothEnabled.subscribe { status in
            receivedStatus = status
        }

        // When
        bluetoothStatusProvider.isBluetoothEnabled.onNext(true)

        // Then
        XCTAssertTrue(receivedStatus!)
    }

    func test_startDiscovery_delegatesCallToScanner() {
        // When
        sorcManager.startDiscovery()

        // Then
        XCTAssertTrue(scanner.startDiscoveryCalled)
    }

    func test_stopDiscovery_delegatesCallToScanner() {
        // When
        sorcManager.stopDiscovery()

        // Then
        XCTAssertTrue(scanner.stopDiscoveryCalled)
    }

    func test_discoveryChange_ifScannerHasDiscoveredSorcs_itContainsDiscoveredSorcs() {
        // Given
        let sorcInfo = SorcInfo.stableTestInstance
        let scannerDiscoveredSorcs = SorcInfos([sorcInfo.sorcID: sorcInfo])
        let newState = DiscoveryChange.State(discoveredSorcs: scannerDiscoveredSorcs, discoveryIsEnabled: true)
        scanner.discoveryChange.onNext(.init(state: newState, action: .initial))

        // When
        let actualState = sorcManager.discoveryChange.state

        // Then
        XCTAssertEqual(actualState, newState)
    }

    func test_discoveryChange_ifScannerDiscoversNewSorc_itNotifiesNewDiscoveredSorc() {
        // Given
        var receivedChange: DiscoveryChange?
        _ = sorcManager.discoveryChange.subscribe { change in
            receivedChange = change
        }

        let newSorcInfo = SorcInfo.stableTestInstance
        let newSorcID = newSorcInfo.sorcID
        let discoveredSorcs = SorcInfos([newSorcID: newSorcInfo])
        let newState = DiscoveryChange.State(discoveredSorcs: discoveredSorcs, discoveryIsEnabled: true)
        let change = DiscoveryChange(state: newState, action: .discovered(sorcID: newSorcID))

        // When
        scanner.discoveryChange.onNext(change)

        // Then
        XCTAssertEqual(receivedChange, change)
    }

    func test_connectToSorc_itDelegatesTheCallToSessionManager() {
        // Given
        let leaseToken = try! LeaseToken(id: "id", leaseID: "leaseID", sorcID: sorcIDA, sorcAccessKey: "key")
        let leaseTokenBlob = try! LeaseTokenBlob(messageCounter: 1, data: "1a")

        // When
        sorcManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)

        // Then
        let expectedArguments = (leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
        XCTAssertTrue(sessionManager.connectToSorcCalledWithArguments! == expectedArguments)
    }

    func test_disconnect_itDelegatesTheCallToSessionManager() {
        // When
        sorcManager.disconnect()

        // Then
        XCTAssertTrue(sessionManager.disconnectCalled)
    }

    func test_connectionChange_ifSessionManagerIsConnecting_itIsConnecting() {
        // Given
        sessionManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .physical),
            action: .connect(sorcID: sorcIDA))
        )

        // When
        let state = sorcManager.connectionChange.state

        // Then
        XCTAssertEqual(state, .connecting(sorcID: sorcIDA, state: .physical))
    }

    func test_connectionChange_ifSessionManagerChangesConnectionState_itNotifiesConnectionStateChange() {
        // Given
        var receivedChange: ConnectionChange?
        _ = sorcManager.connectionChange.subscribe { change in
            receivedChange = change
        }

        // When
        let change = ConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .physical),
            action: .connect(sorcID: sorcIDA)
        )
        sessionManager.connectionChange.onNext(change)

        // Then
        XCTAssertEqual(receivedChange, change)
    }

    func test_requestServiceGrant_itDelegatesTheCallToSessionManager() {
        // When
        sorcManager.requestServiceGrant(serviceGrantIDA)

        // Then
        XCTAssertEqual(sessionManager.requestServiceGrantCalledWithID!, serviceGrantIDA)
    }

    func test_serviceGrantChange_ifSessionManagerIsRequestingServiceGrants_itIsRequestingServiceGrants() {
        // Given
        sessionManager.serviceGrantChange.onNext(.init(
            state: .init(requestingServiceGrantIDs: [1, 2, 3]),
            action: .requestServiceGrant(id: 2, accepted: true)
        ))

        // When
        let state = sorcManager.serviceGrantChange.state

        // Then
        XCTAssertEqual(state, .init(requestingServiceGrantIDs: [1, 2, 3]))
    }

    func test_serviceGrantChange_ifSessionManagerChangesServiceGrantState_itNotifiesServiceGrantChange() {
        // Given
        var receivedChange: ServiceGrantChange?
        _ = sorcManager.serviceGrantChange.subscribe { change in
            receivedChange = change
        }

        // When
        let change = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: [1]),
            action: .requestServiceGrant(id: 1, accepted: true)
        )
        sessionManager.serviceGrantChange.onNext(change)

        // Then
        XCTAssertEqual(receivedChange, change)
    }
}
