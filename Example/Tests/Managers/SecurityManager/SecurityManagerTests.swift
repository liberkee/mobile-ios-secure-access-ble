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

        //        // When
        //        transportManager.connectionChange.onNext(.init(
        //            state: .connected(sorcID: sorcIDA),
        //            action: .connectionEstablished(sorcID: sorcIDA))
        //        )
        //
        //        // Then
        //        let connectedChange = SecureConnectionChange(
        //            state: .connected(sorcID: sorcIDA),
        //            action: .connectionEstablished(sorcID: sorcIDA)
        //        )
        //        XCTAssertEqual(receivedConnectionChange, connectedChange)
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

    //    func test_requestServiceGrant_ifConnectedAndQueueIsNotFullAndNotWaitingForResponse_itSendsMessageToSecurityManager() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        var receivedServiceGrantChange: ServiceGrantChange!
    //        _ = securityManager.serviceGrantChange.subscribeNext { change in
    //            receivedServiceGrantChange = change
    //        }
    //
    //        // When
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //
    //        // Then
    //        let expectedMessage = SorcMessage(
    //            id: SorcMessageID.serviceGrant,
    //            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
    //        )
    //        XCTAssertEqual(transportManager.sendMessageCalledWithMessage!, expectedMessage)
    //
    //        let expectedServiceGrantChange = ServiceGrantChange(
    //            state: .init(requestingServiceGrantIDs: [serviceGrantIDA]),
    //            action: .requestServiceGrant(id: serviceGrantIDA, accepted: true)
    //        )
    //        XCTAssertEqual(receivedServiceGrantChange, expectedServiceGrantChange)
    //    }
    //
    //    func test_requestServiceGrant_ifConnectedAndQueueIsNotFullAndWaitingForResponse_itEnqueuesMessage() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //
    //        var receivedServiceGrantChange: ServiceGrantChange!
    //        _ = securityManager.serviceGrantChange.subscribeNext { change in
    //            receivedServiceGrantChange = change
    //        }
    //
    //        // When
    //        securityManager.requestServiceGrant(serviceGrantIDB)
    //
    //        // Then
    //        let expectedMessage = SorcMessage(
    //            id: SorcMessageID.serviceGrant,
    //            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
    //        )
    //        // did not receive serviceGrantIDB
    //        XCTAssertEqual(transportManager.sendMessageCalledWithMessage!, expectedMessage)
    //
    //        let expectedServiceGrantChange = ServiceGrantChange(
    //            state: .init(requestingServiceGrantIDs: [serviceGrantIDA, serviceGrantIDB]),
    //            action: .requestServiceGrant(id: serviceGrantIDB, accepted: true)
    //        )
    //        XCTAssertEqual(receivedServiceGrantChange, expectedServiceGrantChange)
    //    }
    //
    //    func test_requestServiceGrant_ifConnectedAndMessageIsEnqueuedAndReceivedServiceGrantResponse_itNotfifiesResponseAndItSendsEnqueuedMessage() {
    //
    //        // Given
    //        prepareConnected()
    //
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //        securityManager.requestServiceGrant(serviceGrantIDB)
    //
    //        var receivedServiceGrantChange: ServiceGrantChange!
    //        _ = securityManager.serviceGrantChange.subscribeNext { change in
    //            receivedServiceGrantChange = change
    //        }
    //
    //        // When
    //        transportManager.messageReceived.onNext(.success(serviceGrantAResponseMessage))
    //
    //        // Then
    //        let expectedServiceGrantChange = ServiceGrantChange(
    //            state: .init(requestingServiceGrantIDs: [serviceGrantIDB]),
    //            action: .responseReceived(.init(
    //                sorcID: sorcIDA,
    //                serviceGrantID: serviceGrantIDAResponse,
    //                status: .pending,
    //                responseData: ""
    //            ))
    //        )
    //        XCTAssertEqual(receivedServiceGrantChange!, expectedServiceGrantChange)
    //
    //        let expectedMessage = SorcMessage(
    //            id: SorcMessageID.serviceGrant,
    //            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDB)
    //        )
    //        XCTAssertEqual(transportManager.sendMessageCalledWithMessage!, expectedMessage)
    //    }
    //
    //    func test_requestServiceGrant_ifConnectedAndQueueIsFull_itDoesNotSendMessageAndItNotifiesNotAccepted() {
    //
    //        // Given
    //        let configuration = SessionManager.Configuration(maximumEnqueuedMessages: 2)
    //        securityManager = SessionManager(transportManager: transportManager, configuration: configuration)
    //        prepareConnected()
    //
    //        // added and instantly removed from queue
    //        securityManager.requestServiceGrant(serviceGrantIDB)
    //        // enqueued and staying in queue
    //        securityManager.requestServiceGrant(serviceGrantIDB)
    //        securityManager.requestServiceGrant(serviceGrantIDB)
    //        // not accepted, queue is full
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //
    //        var receivedServiceGrantChange: ServiceGrantChange!
    //        _ = securityManager.serviceGrantChange.subscribeNext { change in
    //            receivedServiceGrantChange = change
    //        }
    //
    //        // When
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //
    //        // Then
    //        let unexpectedMessage = SorcMessage(
    //            id: SorcMessageID.serviceGrant,
    //            payload: ServiceGrantRequest(serviceGrantID: serviceGrantIDA)
    //        )
    //        XCTAssertNotEqual(transportManager.sendMessageCalledWithMessage!, unexpectedMessage)
    //
    //        let expectedServiceGrantChange = ServiceGrantChange(
    //            state: .init(requestingServiceGrantIDs: [serviceGrantIDB, serviceGrantIDB, serviceGrantIDB]),
    //            action: .requestServiceGrant(id: serviceGrantIDA, accepted: false)
    //        )
    //        XCTAssertEqual(receivedServiceGrantChange, expectedServiceGrantChange)
    //    }
    //
    //    func test_requestServiceGrant_ifNotConnected_itDoesNothing() {
    //
    //        // Given
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //
    //        var receivedServiceGrantChange: ServiceGrantChange!
    //        _ = securityManager.serviceGrantChange.subscribeNext { change in
    //            receivedServiceGrantChange = change
    //        }
    //
    //        // When
    //        securityManager.requestServiceGrant(serviceGrantIDA)
    //
    //        // Then
    //        XCTAssertNil(transportManager.sendMessageCalledWithMessage)
    //
    //        let expectedServiceGrantChange = ServiceGrantChange(
    //            state: .init(requestingServiceGrantIDs: []),
    //            action: .initial
    //        )
    //        XCTAssertEqual(receivedServiceGrantChange!, expectedServiceGrantChange)
    //    }

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
    //        transportManager.connectionChange.onNext(.init(
    //            state: .connected(sorcID: sorcIDA),
    //            action: .connectionEstablished(sorcID: sorcIDA))
    //        )
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
