//
//  SessionManagerTests.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils
@testable import SecureAccessBLE
import XCTest

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
private let sorcAccessKey = "1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
private let leaseTokenA = try! LeaseToken(id: "", leaseID: "", sorcID: sorcIDA, sorcAccessKey: sorcAccessKey)
private let leaseTokenBlobA = try! LeaseTokenBlob(messageCounter: 1, data: "1a")
private let serviceGrantIDA = ServiceGrantID(2)
private let serviceGrantIDB = ServiceGrantID(3)
private let serviceGrantIDAResponse = ServiceGrantID(4)
private let serviceGrantAResponseMessage = SorcMessage(rawData: Data(bytes: [
    SorcMessageID.serviceGrantTrigger.rawValue,
    UInt8(serviceGrantIDAResponse), 0x00,
    ServiceGrantResponse.Status.pending.rawValue
]))

private class MockSecurityManager: SecurityManagerType {
    let connectionChange = ChangeSubject<SecureConnectionChange>(state: .disconnected)

    var connectToSorcCalledWithArguments: (leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)?
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        connectToSorcCalledWithArguments = (leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }

    let messageSent = PublishSubject<Result<SorcMessage>>()
    let messageReceived = PublishSubject<Result<SorcMessage>>()

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

    // MARK: - Tests

    func test_init_succeeds() {
        XCTAssertNotNil(sessionManager)
    }

    func test_connectToSorc_ifDisconnected_connectsWithSorc() {
        // Given
        var receivedConnectionChange: ConnectionChange?
        _ = sessionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)

        // Then
        let expectedArguments = (leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
        XCTAssert(securityManager.connectToSorcCalledWithArguments! == expectedArguments)

        let physicalConnectingChange = ConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .physical),
            action: .connect(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, physicalConnectingChange)

        // When
        securityManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .transport),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        ))

        // Then
        let transportConnectingChange = ConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .transport),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, transportConnectingChange)

        // When
        securityManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .transportConnectionEstablished(sorcID: sorcIDA)
        ))

        // Then
        let challengingConnectingChange = ConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .transportConnectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, challengingConnectingChange)

        // When
        securityManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA))
        )

        // Then
        let connectedChange = ConnectionChange(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, connectedChange)
    }

    // To make it possible to retrigger a connect while connecting physically
    func test_connectToSorc_ifPhysicalConnecting_connectsToSecurityManagerAndDoesNotNotifyPhysicalConnecting() {
        // Given
        preparePhysicalConnecting()

        var receivedConnectionChange: ConnectionChange!
        _ = sessionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)

        // Then
        let expectedArguments = (leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
        XCTAssert(securityManager.connectToSorcCalledWithArguments! == expectedArguments)
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

    func test_connectToSorc_ifConnected_doesNothing() {
        // Given
        prepareConnected()

        // When // Then
        connectToSorcAndAssertDoesNothing()
    }

    func test_disconnect_ifConnecting_disconnectsSecurityManagerAndNotifiesDisconnect() {
        // Given
        preparePhysicalConnecting()

        // When // Then
        disconnectAndAssertNotifiesDisconnect()
    }

    func test_disconnect_ifConnected_disconnectsAndNotifiesDisconnect() {
        // Given
        prepareConnected()

        // When // Then
        disconnectAndAssertNotifiesDisconnect()
    }

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

    func test_requestServiceGrant_ifConnectedAndQueueIsNotFullAndNotWaitingForResponse_itSendsMessageToSecurityManager() {
        // Given
        prepareConnected()

        var receivedServiceGrantChange: ServiceGrantChange!
        _ = sessionManager.serviceGrantChange.subscribeNext { change in
            receivedServiceGrantChange = change
        }

        // When
        sessionManager.requestServiceGrant(serviceGrantIDA)

        // Then
        let expectedMessage = SorcMessage(
            id: SorcMessageID.serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
        )
        XCTAssertEqual(securityManager.sendMessageCalledWithMessage!, expectedMessage)

        let expectedServiceGrantChange = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: [serviceGrantIDA]),
            action: .requestServiceGrant(id: serviceGrantIDA, accepted: true)
        )
        XCTAssertEqual(receivedServiceGrantChange, expectedServiceGrantChange)
    }

    func test_requestServiceGrant_ifConnectedAndQueueIsNotFullAndWaitingForResponse_itEnqueuesMessage() {
        // Given
        prepareConnected()

        sessionManager.requestServiceGrant(serviceGrantIDA)

        var receivedServiceGrantChange: ServiceGrantChange!
        _ = sessionManager.serviceGrantChange.subscribeNext { change in
            receivedServiceGrantChange = change
        }

        // When
        sessionManager.requestServiceGrant(serviceGrantIDB)

        // Then
        let expectedMessage = SorcMessage(
            id: SorcMessageID.serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
        )
        // did not receive serviceGrantIDB
        XCTAssertEqual(securityManager.sendMessageCalledWithMessage!, expectedMessage)

        let expectedServiceGrantChange = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: [serviceGrantIDA, serviceGrantIDB]),
            action: .requestServiceGrant(id: serviceGrantIDB, accepted: true)
        )
        XCTAssertEqual(receivedServiceGrantChange, expectedServiceGrantChange)
    }

    func test_requestServiceGrant_ifConnectedAndMessageIsEnqueuedAndReceivedServiceGrantResponse_itNotfifiesResponseAndItSendsEnqueuedMessage() {
        // Given
        prepareConnected()

        sessionManager.requestServiceGrant(serviceGrantIDA)
        sessionManager.requestServiceGrant(serviceGrantIDB)

        var receivedServiceGrantChange: ServiceGrantChange!
        _ = sessionManager.serviceGrantChange.subscribeNext { change in
            receivedServiceGrantChange = change
        }

        // When
        securityManager.messageReceived.onNext(.success(serviceGrantAResponseMessage))

        // Then
        let expectedServiceGrantChange = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: [serviceGrantIDB]),
            action: .responseReceived(.init(
                sorcID: sorcIDA,
                serviceGrantID: serviceGrantIDAResponse,
                status: .pending,
                responseData: ""
            ))
        )
        XCTAssertEqual(receivedServiceGrantChange!, expectedServiceGrantChange)

        let expectedMessage = SorcMessage(
            id: SorcMessageID.serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDB)
        )
        XCTAssertEqual(securityManager.sendMessageCalledWithMessage!, expectedMessage)
    }

    func test_requestServiceGrant_ifConnectedAndQueueIsFull_itDoesNotSendMessageAndItNotifiesNotAccepted() {
        // Given
        let configuration = SessionManager.Configuration(maximumEnqueuedMessages: 2)
        sessionManager = SessionManager(securityManager: securityManager, configuration: configuration)
        prepareConnected()

        // added and instantly removed from queue
        sessionManager.requestServiceGrant(serviceGrantIDB)
        // enqueued and staying in queue
        sessionManager.requestServiceGrant(serviceGrantIDB)
        sessionManager.requestServiceGrant(serviceGrantIDB)
        // not accepted, queue is full
        sessionManager.requestServiceGrant(serviceGrantIDA)

        var receivedServiceGrantChange: ServiceGrantChange!
        _ = sessionManager.serviceGrantChange.subscribeNext { change in
            receivedServiceGrantChange = change
        }

        // When
        sessionManager.requestServiceGrant(serviceGrantIDA)

        // Then
        let unexpectedMessage = SorcMessage(
            id: SorcMessageID.serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
        )
        XCTAssertNotEqual(securityManager.sendMessageCalledWithMessage!, unexpectedMessage)

        let expectedServiceGrantChange = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: [serviceGrantIDB, serviceGrantIDB, serviceGrantIDB]),
            action: .requestServiceGrant(id: serviceGrantIDA, accepted: false)
        )
        XCTAssertEqual(receivedServiceGrantChange, expectedServiceGrantChange)
    }

    func test_requestServiceGrant_ifNotConnected_itDoesNothing() {
        // Given
        var receivedServiceGrantChange: ServiceGrantChange!
        _ = sessionManager.serviceGrantChange.subscribeNext { change in
            receivedServiceGrantChange = change
        }

        // When
        sessionManager.requestServiceGrant(serviceGrantIDA)

        // Then
        XCTAssertNil(securityManager.sendMessageCalledWithMessage)

        let expectedServiceGrantChange = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: []),
            action: .initial
        )
        XCTAssertEqual(receivedServiceGrantChange!, expectedServiceGrantChange)
    }

    // MARK: - State preparation

    private func preparePhysicalConnecting() {
        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
        securityManager.connectToSorcCalledWithArguments = nil
    }

    private func prepareTransportConnecting() {
        preparePhysicalConnecting()
        securityManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .transport),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        ))
    }

    private func prepareChallengingConnecting() {
        prepareTransportConnecting()
        securityManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .transportConnectionEstablished(sorcID: sorcIDA)
        ))
    }

    private func prepareConnected() {
        prepareChallengingConnecting()
        securityManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA))
        )
    }

    // MARK: - Helper

    private func connectToSorcAndAssertDoesNothing(file: StaticString = #file, line: UInt = #line) {
        var receivedConnectionChange: ConnectionChange!
        _ = sessionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)

        // Then
        XCTAssertNil(
            securityManager.connectToSorcCalledWithArguments,
            "securityManager.connectToSorc() was called, but should not",
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
        var receivedConnectionChange: ConnectionChange!
        _ = sessionManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        sessionManager.disconnect()

        securityManager.connectionChange.onNext(.init(state: .disconnected, action: .disconnect))

        // Then
        XCTAssertTrue(securityManager.disconnectCalled, "securityManager.disconnect() was not called")

        let expectedChange = ConnectionChange(state: .disconnected, action: .disconnect)
        XCTAssertEqual(
            receivedConnectionChange,
            expectedChange,
            "Should receive disconnected state and disconnect action, but did not",
            file: file,
            line: line
        )
    }
}
