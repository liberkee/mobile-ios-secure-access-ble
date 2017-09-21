//
//  SecurityManagerTests.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE
import CommonUtils

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
private let sorcAccessKey = "1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
private let leaseTokenA = try! LeaseToken(id: "", leaseID: "", sorcID: sorcIDA, sorcAccessKey: sorcAccessKey)
private let leaseTokenBlobA = try! LeaseTokenBlob(messageCounter: 1, data: "1a")
private let serviceGrantIDA = ServiceGrantID(2)

private class MockTransportManager: TransportManagerType {

    let connectionChange = ChangeSubject<TransportConnectionChange>(state: .disconnected)

    var connectToSorcCalledWithSorcID: SorcID?
    func connectToSorc(_ sorcID: SorcID) {
        connectToSorcCalledWithSorcID = sorcID
    }

    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }

    let dataSent = PublishSubject<Result<Data>>()
    let dataReceived = PublishSubject<Result<Data>>()

    var sendDataCalledWithData: Data?
    func sendData(_ data: Data) {
        sendDataCalledWithData = data
    }
}

class SecurityManagerTests: XCTestCase {

    fileprivate let transportManager = MockTransportManager()
    var securityManager: SecurityManager!

    override func setUp() {
        super.setUp()

        securityManager = SecurityManager(transportManager: transportManager)
    }

    // MARK: - Tests

    func test_init_succeeds() {
        XCTAssertNotNil(securityManager)
    }

    func test_connectToSorc_ifDisconnected_connectsWithSorc() {

        // Given
        var receivedConnectionChange: SecureConnectionChange?
        _ = securityManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        securityManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)

        // Then
        XCTAssertEqual(transportManager.connectToSorcCalledWithSorcID!, sorcIDA)

        let physicalConnectingChange = SecureConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .physical),
            action: .connect(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, physicalConnectingChange)

        // When
        transportManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .requestingMTU),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        ))

        // Then
        let transportConnectingChange = SecureConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .transport),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, transportConnectingChange)

        // When
        transportManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        ))

        // Then
        let challengingConnectingChange = SecureConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .transportConnectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, challengingConnectingChange)

        // TODO: PLAM-1568 implement counter part for encryption or mock Challenger (recommended)
        // reason: Challenger has random data generation
        // example
        //
        // send: challengePhone
        // 30 00 7d00 01 37663634346130372d363662302d343438652d626136372d37366463656331646330636331623065613765342d653966352d346638302d393466332d39356630343262363936656234666138313331662d646262332d346137632d616365662d65656565646561376431326626964e68b5a0eaa2ed89277a78fe331f
        //
        // received: challengeSorcResponse
        // 36 00 2100 02 52423676688b220def81b4a508bc4e963e7d80cf2a21bf045ac8002e7d518f0e
        //
        // send: challengePhoneResonse
        // 30 00 1100 04 ebe47dec44b6926dd9e834ccdce524f7
    }

    // To make it possible to retrigger a connect while connecting physically
    func test_connectToSorc_ifPhysicalConnecting_connectsToTransportManagerAndDoesNotNotifyPhysicalConnecting() {

        // Given
        preparePhysicalConnecting()

        var receivedConnectionChange: SecureConnectionChange!
        _ = securityManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        securityManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)

        // Then
        XCTAssertEqual(transportManager.connectToSorcCalledWithSorcID, sorcIDA)
        XCTAssertEqual(receivedConnectionChange.action, .initial)
    }

    func test_connectToSorc_ifTransportConnecting_doesNothing() {

        // Given
        prepareTransportConnecting()

        // When // Then
        connectToSorcAndAssertDoesNothing()
    }

    func test_connectToSorc_ifChallengingConnecting_doesNothing() {

        // Given
        prepareChallengingConnecting()

        // When // Then
        connectToSorcAndAssertDoesNothing()
    }

    // TODO: PLAM-1568 implement
    //    func test_connectToSorc_ifConnected_doesNothing() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        // When // Then
    //        connectToSorcAndAssertDoesNothing()
    //    }

    func test_disconnect_ifConnecting_disconnectsTransportManagerAndNotifiesDisconnect() {

        // Given
        preparePhysicalConnecting()

        // When // Then
        disconnectAndAssertNotifiesDisconnect()
    }

    // TODO: PLAM-1568 implement
    //    func test_disconnect_ifConnected_disconnectsAndNotifiesDisconnect() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        // When // Then
    //        disconnectAndAssertNotifiesDisconnect()
    //    }

    func test_disconnect_ifNotConnectingOrConnected_doesNothing() {

        // Given
        var receivedConnectionChange: SecureConnectionChange!
        _ = securityManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        securityManager.disconnect()

        // Then
        XCTAssertFalse(transportManager.disconnectCalled)
        XCTAssertEqual(receivedConnectionChange.action, .initial)
    }

    // TODO: PLAM-1568 implement some tests for sending and receiving messages in connected state
    //    func test_sendMessage_ifConnected_itSendsDataToSecurityManager() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        var receivedMessageSent: Result<SorcMessage>?
    //        _ = securityManager.messageSent.subscribeNext { result in
    //            receivedMessageSent = result
    //        }
    //
    //        // When
    //        let message = SorcMessage(
    //            id: .serviceGrant,
    //            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
    //        )
    //        securityManager.sendMessage(message)
    //
    //        // Then
    //        let expectedData = …
    //        XCTAssertEqual(transportManager.sendDataCalledWithData!, expectedData)
    //
    //        if case let .success(receivedMessage) = receivedMessageSent! {
    //            XCTAssertEqual(receivedMessage, message)
    //        } else {
    //            XCTFail()
    //        }
    //    }

    func test_requestServiceGrant_ifNotConnected_itDoesNothing() {

        // When
        let message = SorcMessage(
            id: .serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
        )
        securityManager.sendMessage(message)

        // Then
        XCTAssertNil(transportManager.sendDataCalledWithData)
    }

    // MARK: - State preparation

    private func preparePhysicalConnecting() {
        securityManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
        transportManager.connectToSorcCalledWithSorcID = nil
    }

    private func prepareTransportConnecting() {
        preparePhysicalConnecting()
        transportManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .requestingMTU),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        ))
    }

    private func prepareChallengingConnecting() {
        prepareTransportConnecting()
        transportManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        ))
    }

    //    private func prepareConnected() {
    //        prepareChallengingConnecting()
    //        ...
    //    }

    // MARK: - Helper

    private func connectToSorcAndAssertDoesNothing(file: StaticString = #file, line: UInt = #line) {

        var receivedConnectionChange: SecureConnectionChange!
        _ = securityManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        securityManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)

        // Then
        XCTAssertNil(
            transportManager.connectToSorcCalledWithSorcID,
            "transportManager.connectToSorc() was called, but should not",
            file: file,
            line: line
        )
        XCTAssertEqual(
            receivedConnectionChange.action,
            .initial,
            "connectionChange was received, but should not",
            file: file,
            line: line
        )
    }

    private func disconnectAndAssertNotifiesDisconnect(file: StaticString = #file, line: UInt = #line) {

        var receivedConnectionChange: SecureConnectionChange!
        _ = securityManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        securityManager.disconnect()

        transportManager.connectionChange.onNext(.init(state: .disconnected, action: .disconnect))

        // Then
        XCTAssertTrue(transportManager.disconnectCalled, "transportManager.disconnect() was not called")

        let expectedChange = SecureConnectionChange(state: .disconnected, action: .disconnect)
        XCTAssertEqual(
            receivedConnectionChange,
            expectedChange,
            "Should receive disconnected state and disconnect action, but did not",
            file: file,
            line: line
        )
    }
}
