//
//  SessionManagerTests.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE
import CommonUtils

private let sorcIDA = "be2fecaf-734b-4252-8312-59d477200a20"
private let sorcAccessKey = "1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
private let leaseTokenA = LeaseToken(id: "", leaseID: "", sorcID: sorcIDA, sorcAccessKey: sorcAccessKey)
private let leaseTokenBlobA = LeaseTokenBlob(messageCounter: 1, data: "")

private class MockSecurityManager: SecurityManagerType {

    let connectionChange = ChangeSubject<SecureConnectionChange>(state: .disconnected)

    var connectToSorcCalledWithArguments: (leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)?
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        connectToSorcCalledWithArguments = (leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    let messageSent = PublishSubject<Result<SorcMessage>>()
    let messageReceived = PublishSubject<Result<SorcMessage>>()

    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }

    var sendMessageCalledWithMessage: SorcMessage?
    func sendMessage(_ message: SorcMessage) {
        sendMessageCalledWithMessage = message
    }
}

class SessionManagerTests: XCTestCase {

    fileprivate let securityManager = MockSecurityManager()
    var sessionManager: SessionManager!

    override func setUp() {
        super.setUp()

        sessionManager = SessionManager(securityManager: securityManager)
    }

    func test_init_succeeds() {
        XCTAssertNotNil(sessionManager)
    }

    //    func test_connectToSorc_ifDisconnected_connectsWithSorc() {
    //
    //        // Given
    //        var receivedConnectionChange: ConnectionChange?
    //        _ = sessionManager.connectionChange.subscribeNext { change in
    //            receivedConnectionChange = change
    //        }
    //
    //        // When
    //        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
    //
    //        // Then
    //        XCTAssertEqual(securityManager.connectToSorcCalledWithArguments, sorcIDA)
    //
    //        let physicalConnectingChange = ConnectionChange(
    //            state: .connecting(sorcID: sorcIDA, state: .physical),
    //            action: .connect(sorcID: sorcIDA)
    //        )
    //        XCTAssertEqual(receivedConnectionChange, physicalConnectingChange)
    //
    //        // When
    //        securityManager.connectionChange.onNext(.init(
    //            state: .connecting(sorcID: sorcIDA, state: .requestingMTU),
    //            action: .physicalConnectionEstablished(sorcID: sorcIDA)
    //        ))
    //
    //        // Then
    //        let transportConnectingChange = ConnectionChange(
    //            state: .connecting(sorcID: sorcIDA, state: .transport),
    //            action: .physicalConnectionEstablished(sorcID: sorcIDA)
    //        )
    //        XCTAssertEqual(receivedConnectionChange, transportConnectingChange)
    //
    //        // When
    //        securityManager.connectionChange.onNext(.init(
    //            state: .connected(sorcID: sorcIDA),
    //            action: .connectionEstablished(sorcID: sorcIDA))
    //        )
    //
    //        // Then
    //        let challengeConnectingChange = ConnectionChange(
    //            state: .connecting(sorcID: sorcIDA, state: .challenging),
    //            action: .transportConnectionEstablished(sorcID: sorcIDA)
    //        )
    //        XCTAssertEqual(receivedConnectionChange, challengeConnectingChange)
    //
    //        // transport manager receives challenge result
    //        // transport manager sends challenge result
    //    }

    // To make it possible to retrigger a connect while connecting physically
    //    func test_connectToSorc_ifPhysicalConnecting_connectsWithSorcIDOfLeaseTokenAndDoesNotNotifyPhysicalConnecting() {
    //
    //        // Given
    //        preparePhysicalConnecting()
    //
    //        var receivedConnectionChange: ConnectionChange!
    //        _ = sessionManager.connectionChange.subscribeNext { change in
    //            receivedConnectionChange = change
    //        }
    //
    //        // When
    //        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
    //
    //        // Then
    //        XCTAssertEqual(securityManager.connectToSorcCalledWithArguments, sorcIDA)
    //        XCTAssertEqual(receivedConnectionChange.action, .initial)
    //    }

    // func test_connectToSorc_ifTransportConnecting_doesNothing()

    //    func test_connectToSorc_ifConnected_doesNothing() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        var receivedConnectionChange: ConnectionChange!
    //        _ = sessionManager.connectionChange.subscribeNext { change in
    //            receivedConnectionChange = change
    //        }
    //
    //        // When
    //        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
    //
    //        // Then
    //            XCTAssertNil(transportManager.connectToSorcCalledWithSorcID)
    //            XCTAssertEqual(receivedConnectionChange.action, .initial)
    //    }

    //    func test_disconnect_ifConnecting_disconnectsAndNotifiesDisconnect() {
    //
    //        // Given
    //        preparePhysicalConnecting()
    //
    //        var receivedConnectionChange: ConnectionChange!
    //        _ = sessionManager.connectionChange.subscribeNext { change in
    //            receivedConnectionChange = change
    //        }
    //
    //        // When
    //        sessionManager.disconnect()
    //
    //        // Then
    //        XCTAssertTrue(securityManager.disconnectCalled)
    //
    //        let expectedChange = ConnectionChange(state: .disconnected, action: .disconnect)
    //        XCTAssertEqual(receivedConnectionChange, expectedChange)
    //    }

    //    func test_disconnect_ifConnected_disconnectsAndNotifiesDisconnect() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        var receivedConnectionChange: ConnectionChange!
    //        _ = sessionManager.connectionChange.subscribeNext { change in
    //            receivedConnectionChange = change
    //        }
    //
    //        // When
    //        sessionManager.disconnect()
    //
    //        // Then
    //        XCTAssertTrue(transportManager.disconnectCalled)
    //
    //        let expectedChange = ConnectionChange(state: .disconnected, action: .disconnect)
    //        XCTAssertEqual(receivedConnectionChange, expectedChange)
    //    }

    func test_disconnect_ifNotConnectingOrConnected_doesNothing() {

        // Given
        var receivedConnectionChange: ConnectionChange!
        _ = sessionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        sessionManager.disconnect()

        // Then
        XCTAssertFalse(securityManager.disconnectCalled)
        XCTAssertEqual(receivedConnectionChange.action, .initial)
    }

    private func preparePhysicalConnecting() {
        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
        securityManager.connectToSorcCalledWithArguments = nil
    }

    //    private func prepareConnected() {
    //        // TODO: PLAM-959
    //    }
}
