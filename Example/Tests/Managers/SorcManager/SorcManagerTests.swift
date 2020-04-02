//
//  SorcManagerTests.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

@testable import SecureAccessBLE
import XCTest

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
private let sorcIDB = UUID(uuidString: "fd487104-c03b-4a94-8162-08826746b52d")!

private let serviceGrantIDA: UInt16 = 0x01

private class MockBluetoothStatusProvider: BluetoothStatusProviderType {
    let bluetoothState = BehaviorSubject<BluetoothState>(value: .poweredOff)
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

    var startDiscoveryKnownSorcCalled = false
    var startDiscoveryTimeout: TimeInterval?
    func startDiscovery(sorcID _: SorcID, timeout: TimeInterval?) {
        startDiscoveryKnownSorcCalled = true
        startDiscoveryTimeout = timeout
    }

    var stopDiscoveryCalled = false
    func stopDiscovery() {
        stopDiscoveryCalled = true
    }
}

private class MockSessionManager: SessionManagerType {
    let bulkServiceChange = ChangeSubject<BulkServiceChange>(state: false)

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

    var requestBulk: MobileBulk?
    func requestBulk(_ bulk: MobileBulk) {
        requestBulk = bulk
    }
}

private class SorcInterceptorMock: SorcInterceptor {
    var consumeResult: ServiceGrantChange?
    func consume(change _: ServiceGrantChange) -> ServiceGrantChange? {
        return consumeResult
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

    func test_bluetoothState_ifNewStatusIsProvided_itNotifiesNewStatus() {
        // Given
        var receivedState: BluetoothState?
        _ = sorcManager.bluetoothState.subscribe { status in
            receivedState = status
        }

        // When
        let newState = BluetoothState.unauthorized
        bluetoothStatusProvider.bluetoothState.onNext(newState)

        // Then
        XCTAssertEqual(newState, receivedState)
    }

    func test_startDiscovery_delegatesCallToScanner() {
        // When
        sorcManager.startDiscovery()

        // Then
        XCTAssertTrue(scanner.startDiscoveryCalled)
    }

    func test_startDiscoveryWithSpecificSorc_delegatesCallToScanner() {
        // When
        let sorcID = UUID(uuidString: "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f")!
        sorcManager.startDiscovery(sorcID: sorcID, timeout: 22)

        // Then
        XCTAssertTrue(scanner.startDiscoveryKnownSorcCalled)
        XCTAssertEqual(scanner.startDiscoveryTimeout, 22)
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
            action: .connect(sorcID: sorcIDA)
        ))

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

    func test_requestBulk_itDeledatesTheCallToSessionManager() {
        let metadata =
            """
            {\"revision\" : \"58fbf1b56958d47dd08987cba89554c430f2c8ca#000000\",
            \"anchor\" : \"Tugen2Config\",
            \"signature\" : \"MD4CHQCTDQjGXFF0ar2tVR2Og3Tc7sTQPrJTd3T\\/T\\/kMAh0AiKEE6SWqVl+zhATQsitq05wgqPlAo\\/G\\/KEb0YQ==\",
            \"deviceId\" : \"00000000-0000-0000-0000-000000000000\",
            \"firmwareVersion\" : \"0.8.69RC4\"}
            """
        let content = "AAAAAAUAAAAAAAAAAgACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        let mobileBulk = try? MobileBulk(bulkID: sorcIDA, type: .configBulk, metadata: metadata, content: content)
        // When
        sorcManager.requestBulk(mobileBulk!)

        // Then
        XCTAssertEqual(sessionManager.requestBulk, mobileBulk)
    }

    func test_bulkResponseChange_ifSessionManagerIsRequesting_itIsRequestingBulkMessage() {
        // Given
        sessionManager.bulkServiceChange.onNext(.init(state: true, action: .requestBulk))

        // When
        let state = sorcManager.bulkServiceChange.state

        // Then
        XCTAssertEqual(state, true)
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

    func test_bulkResponseChange_ifSessionManagerChangesBulkResponseState_itNotifiesBulkMessageChange() {
        // Given
        var receivedChange: BulkServiceChange?
        _ = sorcManager.bulkServiceChange.subscribe { change in
            receivedChange = change
        }

        // When
        let change = BulkServiceChange(state: true, action: .requestBulk)
        sessionManager.bulkServiceChange.onNext(change)

        // Then
        XCTAssertEqual(receivedChange, change)
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

    func test_serviceGrantChange_interceptorConsumesChange_changeNotNotified() {
        // Given
        var receivedChange: ServiceGrantChange?
        _ = sorcManager.serviceGrantChange.subscribe { change in
            receivedChange = change
        }
        let interceptor = SorcInterceptorMock()
        interceptor.consumeResult = nil
        sorcManager.registerInterceptor(interceptor)

        // When
        let change = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: [1]),
            action: .requestServiceGrant(id: 1, accepted: true)
        )
        sessionManager.serviceGrantChange.onNext(change)

        // Then
        XCTAssertEqual(receivedChange, ServiceGrantChange.initialWithState(.init(requestingServiceGrantIDs: [])))
    }
}
