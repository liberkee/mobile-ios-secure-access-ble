//
//  TransportManagerTests.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE
import CommonUtils

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
private let mtuRequestData = Data(bytes: [0x30, 0x00, 0x01, 0x00, 0x06])
private let mtuReceiveData = Data(bytes: [0x36, 0x00, 0x03, 0x00, 0x07, 0xB6, 0x00])
private let messageDataA = Data(bytes: [0xAB, 0xCD, 0xEF])
private let frameDataA = Data(bytes: [0x30, 0x00, 0x03, 0x00, 0xAB, 0xCD, 0xEF])

private class MockConnectionManager: ConnectionManagerType {

    let connectionChange = ChangeSubject<PhysicalConnectionChange>(state: .disconnected)

    var connectToSorcCalledWithSorcID: SorcID?
    func connectToSorc(_ sorcID: SorcID) {
        connectToSorcCalledWithSorcID = sorcID
    }

    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }

    let dataSent = PublishSubject<Error?>()
    let dataReceived = PublishSubject<Result<Data>>()

    var sendDataCalledWithData: Data?
    func sendData(_ data: Data) {
        sendDataCalledWithData = data
    }
}

class TransportManagerTests: XCTestCase {

    fileprivate let connectionManager = MockConnectionManager()
    var transportManager: TransportManager!

    override func setUp() {
        super.setUp()

        transportManager = TransportManager(connectionManager: connectionManager)
    }

    // MARK: - Tests

    func test_init_succeeds() {
        XCTAssertNotNil(transportManager)
    }

    func test_connectToSorc_ifDisconnected_connectsWithSorc() {

        // Given
        var receivedConnectionChange: TransportConnectionChange?
        _ = transportManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        transportManager.connectToSorc(sorcIDA)

        // Then
        XCTAssertEqual(connectionManager.connectToSorcCalledWithSorcID!, sorcIDA)

        let physicalConnectingChange = TransportConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .physical),
            action: .connect(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, physicalConnectingChange)

        // When
        connectionManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        ))

        // Then
        let transportConnectingChange = TransportConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .requestingMTU),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, transportConnectingChange)

        XCTAssertEqual(connectionManager.sendDataCalledWithData, mtuRequestData)

        // When
        connectionManager.dataSent.onNext(nil)
        connectionManager.dataReceived.onNext(.success(mtuReceiveData))

        // Then
        let connectedChange = TransportConnectionChange(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, connectedChange)
    }

    // To make it possible to retrigger a connect while connecting physically
    func test_connectToSorc_ifPhysicalConnecting_connectsToConnectionManagerAndDoesNotNotifyPhysicalConnecting() {

        // Given
        preparePhysicalConnecting()

        var receivedConnectionChange: TransportConnectionChange!
        _ = transportManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        transportManager.connectToSorc(sorcIDA)

        // Then
        XCTAssertEqual(connectionManager.connectToSorcCalledWithSorcID, sorcIDA)
        XCTAssertEqual(receivedConnectionChange.action, .initial)
    }

    func test_connectToSorc_ifTransportConnecting_doesNothing() {

        // Given
        prepareTransportConnecting()

        // When // Then
        connectToSorcAndAssertDoesNothing()
    }

    func test_connectToSorc_ifConnected_doesNothing() {

        // Given
        prepareConnected()

        // When // Then
        connectToSorcAndAssertDoesNothing()
    }

    func test_disconnect_ifConnecting_disconnectsConnectionManagerAndNotifiesDisconnect() {

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
        var receivedConnectionChange: TransportConnectionChange!
        _ = transportManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        transportManager.disconnect()

        // Then
        XCTAssertFalse(connectionManager.disconnectCalled)
        XCTAssertEqual(receivedConnectionChange.action, .initial)
    }

    func test_sendData_ifConnectedAndNotSendingPackage_itSendsData() {

        // Given
        prepareConnected()

        var receivedSentData: Result<Data>?
        _ = transportManager.dataSent.subscribeNext { data in
            receivedSentData = data
        }

        // When
        transportManager.sendData(messageDataA)

        // Then
        XCTAssertEqual(connectionManager.sendDataCalledWithData!, frameDataA)

        // When
        connectionManager.dataSent.onNext(nil)

        // Then
        if case let .success(data) = receivedSentData! {
            XCTAssertEqual(data, messageDataA)
        } else {
            XCTFail("receivedSentData is nil")
        }
    }

    func test_sendData_ifConnectedAndSendingPackage_itDoesNothing() {

        // Given
        prepareConnected()

        transportManager.sendData(messageDataA)
        connectionManager.sendDataCalledWithData = nil

        // When // Then
        sendDataAndAssertDoesNothing()
    }

    func test_sendData_ifNotConnected_itDoesNothing() {

        // When // Then
        sendDataAndAssertDoesNothing()
    }

    // MARK: - State preparation

    private func preparePhysicalConnecting() {
        transportManager.connectToSorc(sorcIDA)
        connectionManager.connectToSorcCalledWithSorcID = nil
    }

    private func prepareTransportConnecting() {
        preparePhysicalConnecting()
        connectionManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        ))
    }

    private func prepareConnected() {
        prepareTransportConnecting()
        connectionManager.dataSent.onNext(nil)
        connectionManager.dataReceived.onNext(.success(mtuReceiveData))
    }

    // MARK: - Helper

    private func connectToSorcAndAssertDoesNothing(file: StaticString = #file, line: UInt = #line) {

        var receivedConnectionChange: TransportConnectionChange!
        _ = transportManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        transportManager.connectToSorc(sorcIDA)

        // Then
        XCTAssertNil(
            connectionManager.connectToSorcCalledWithSorcID,
            "connectionManager.connectToSorc() was called, but should not",
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

        var receivedConnectionChange: TransportConnectionChange!
        _ = transportManager.connectionChange.subscribeNext { change in
            receivedConnectionChange = change
        }

        // When
        transportManager.disconnect()

        connectionManager.connectionChange.onNext(.init(state: .disconnected, action: .disconnect(sorcID: sorcIDA)))

        // Then
        XCTAssertTrue(connectionManager.disconnectCalled, "connectionManager.disconnect() was not called")

        let expectedChange = TransportConnectionChange(state: .disconnected, action: .disconnect)
        XCTAssertEqual(
            receivedConnectionChange,
            expectedChange,
            "Should receive disconnected state and disconnect action, but did not",
            file: file,
            line: line
        )
    }

    private func sendDataAndAssertDoesNothing(file: StaticString = #file, line: UInt = #line) {

        // Given
        var receivedSentData: Result<Data>?
        _ = transportManager.dataSent.subscribeNext { data in
            receivedSentData = data
        }

        // When
        transportManager.sendData(messageDataA)

        // Then
        XCTAssertNil(connectionManager.sendDataCalledWithData, file: file, line: line)
        XCTAssertNil(receivedSentData, file: file, line: line)
    }
}
