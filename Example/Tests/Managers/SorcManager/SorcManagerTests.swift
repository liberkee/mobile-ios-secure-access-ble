//
//  SorcManagerTests.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE
import CommonUtils

private let sorcIDA = "be2fecaf-734b-4252-8312-59d477200a20"
private let sorcIDB = "fd487104-c03b-4a94-8162-08826746b52d"

private let serviceGrantIDA: UInt16 = 0x01

private class MockBluetoothStatusProvider: BluetoothStatusProviderType {
    let isBluetoothEnabled = BehaviorSubject<Bool>(value: false)
}

private class MockScanner: ScannerType {
    let discoveryChange = ChangeSubject<DiscoveryChange>(state: [:])
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

    let serviceGrantResultReceived = PublishSubject<ServiceGrantResult>()

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

    func test_isBluetoothEnabled_ifTrueIsProvided_isTrue() {

        // Given
        bluetoothStatusProvider.isBluetoothEnabled.onNext(true)

        // When
        let isEnabled = sorcManager.isBluetoothEnabled.value

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_isBluetoothEnabled_ifNewStatusIsProvided_itNotifiesNewStatus() {

        // Given
        var receivedStatus: Bool?
        _ = sorcManager.isBluetoothEnabled.subscribeNext { status in
            receivedStatus = status
        }

        // When
        bluetoothStatusProvider.isBluetoothEnabled.onNext(true)

        // Then
        XCTAssertTrue(receivedStatus!)
    }

    func test_discoveryChange_ifScannerHasDiscoveredSorcs_itContainsDiscoveredSorcs() {

        // Given
        let sorcInfo = SorcInfo.stableTestInstance
        let scannerDiscoveredSorcs = [sorcInfo.sorcID: sorcInfo]
        scanner.discoveryChange.onNext(.init(state: scannerDiscoveredSorcs, action: .initial))

        // When
        let discoveredSorcs = sorcManager.discoveryChange.state

        // Then
        XCTAssertEqual(discoveredSorcs, scannerDiscoveredSorcs)
    }

    func test_discoveryChange_ifScannerDiscoversNewSorc_itNotifiesNewDiscoveredSorc() {

        // Given
        var receivedChange: DiscoveryChange?
        _ = sorcManager.discoveryChange.subscribeNext { change in
            receivedChange = change
        }

        let newSorcInfo = SorcInfo.stableTestInstance
        let newSorcID = newSorcInfo.sorcID
        let change = DiscoveryChange(state: [newSorcID: newSorcInfo], action: .discovered(sorcID: newSorcID))

        // When
        scanner.discoveryChange.onNext(change)

        // Then
        XCTAssertEqual(receivedChange, change)
    }

    func test_connectToSorc_itDelegatesTheCallToSessionManager() {

        // Given
        let leaseToken = LeaseToken(id: "id", leaseID: "leaseID", sorcID: "sorcID", sorcAccessKey: "key")
        let leaseTokenBlob = LeaseTokenBlob(messageCounter: 1, data: "")

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
        _ = sorcManager.connectionChange.subscribeNext { change in
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

    func test_serviceGrantResultReceived_ifSessionManagerReceivesResult_itReceivesResult() {

        // Given
        var receivedResult: ServiceGrantResult?
        _ = sorcManager.serviceGrantResultReceived.subscribeNext { result in
            receivedResult = result
        }

        // When
        let response = ServiceGrantResponse(
            sorcID: sorcIDA,
            serviceGrantID: serviceGrantIDA,
            status: .success,
            responseData: "responseData"
        )
        let result = ServiceGrantResult.success(response)
        sessionManager.serviceGrantResultReceived.onNext(result)

        // Then
        XCTAssertEqual(receivedResult, result)
    }
}
