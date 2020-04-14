//
//  SessionManagerTests.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

@testable import SecureAccessBLE
import XCTest

private let sorcIDA = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
private let sorcAccessKey = "1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a"
private let leaseTokenA = try! LeaseToken(id: "", leaseID: "", sorcID: sorcIDA, sorcAccessKey: sorcAccessKey)
private let leaseTokenBlobA = try! LeaseTokenBlob(messageCounter: 1, data: "1a")
private let serviceGrantIDA = ServiceGrantID(2)
private let serviceGrantIDB = ServiceGrantID(3)
private let serviceGrantIDAResponse = ServiceGrantID(4)
private let serviceGrantAResponseMessage = SorcMessage(rawData: Data([
    SorcMessageID.serviceGrantTrigger.rawValue,
    UInt8(serviceGrantIDAResponse), 0x00,
    ServiceGrantResponse.Status.pending.rawValue
]))
private let mobileBulkResponseMessage = SorcMessage(rawData: Data([
    0x61, // message id
    0x02, // protocol version
    0xBE, 0x2F, 0xEC, 0xAF, 0x73, 0x4B, 0x42, 0x52, 0x83, 0x12, 0x59, 0xD4, 0x77, 0x20, 0x0A, 0x20, // bulk id
    0x0C, 0x00, 0x00, 0x00, // anchor length, little endian uint32
    0x54, 0x75, 0x67, 0x65, 0x6E, 0x32, 0x43, 0x6F, 0x6E, 0x66, 0x69, 0x67, // anchor
    0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
    0x48, 0x65, 0x6C, 0x6C, 0x6F, // revision
    0x8C, 0x00, 0x00, 0x00 // message, uint32
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

        let sendHeartBeatsTimer: CreateTimer = { _ in self.defaultTimer() }

        let checkHeartbeatsResponseTimer: CreateTimer = { _ in self.defaultTimer() }

        sessionManager = SessionManager(securityManager: securityManager,
                                        sendHeartbeatsTimer: sendHeartBeatsTimer,
                                        checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer)
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
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        ))

        // Then
        let challengingConnectingChange = ConnectionChange(
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        )
        XCTAssertEqual(receivedConnectionChange, challengingConnectingChange)

        // When
        securityManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        ))

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

    func test_requestBulk_ifConnectedAndQueueIsNotFullAndNotWaitingForResponse_itSendsMessageToSecurityManager() {
        // Given
        prepareConnected()

        var receivedMobileBulkChange: MobileBulkChange!
        _ = sessionManager.mobileBulkChange.subscribeNext { change in
            receivedMobileBulkChange = change
        }

        // When
        sessionManager.requestBulk(mobileBulk1!)

        // Then
        let bulkTransmitMessage = try? BulkTransmitMessage(mobileBulk: mobileBulk1!)
        let expectedMessage = SorcMessage(id: .bulkTransferRequest, payload: bulkTransmitMessage!)
        XCTAssertEqual(securityManager.sendMessageCalledWithMessage!, expectedMessage)

        let expectedMobilebulkChange = MobileBulkChange(
            state: .init(requestingBulkIDs: [sorcIDA]),
            action: .requestMobileBulk(bulkID: sorcIDA, accepted: true)
        )
        XCTAssertEqual(receivedMobileBulkChange, expectedMobilebulkChange)
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

    func test_requestMobileBulk_ifConnectedAndQueueIsNotFullAndWaitingForResponse_itEnqueuesMessage() {
        // Given
        prepareConnected()

        sessionManager.requestBulk(mobileBulk1!)

        var receivedMobileBulkChange: MobileBulkChange!
        _ = sessionManager.mobileBulkChange.subscribeNext { change in
            receivedMobileBulkChange = change
        }

        // When
        sessionManager.requestBulk(mobileBulk2!)

        // Then
        let bulkTransmitMessage = try? BulkTransmitMessage(mobileBulk: mobileBulk1!)
        let expectedMessage = SorcMessage(id: .bulkTransferRequest, payload: bulkTransmitMessage!)

        // did not receive mobilebulk2
        XCTAssertEqual(securityManager.sendMessageCalledWithMessage!, expectedMessage)

        let expectedMobilebulkChange = MobileBulkChange(
            state: .init(requestingBulkIDs: [sorcIDA, sorcIDA]),
            action: .requestMobileBulk(bulkID: sorcIDA, accepted: true)
        )
        XCTAssertEqual(receivedMobileBulkChange, expectedMobilebulkChange)
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

    func test_requestMobilebulk_ifConnectedAndMessageIsEnqueuedAndReceivedError_itNotfifiesError() {
        // Given
        prepareConnected()

        sessionManager.requestBulk(mobileBulk1!)

        var receivedMobileBulk: MobileBulkChange!
        _ = sessionManager.mobileBulkChange.subscribeNext { change in
            receivedMobileBulk = change
        }

        // When
        let error = MobileBulkResponse.Error.badRevisionFormat
        securityManager.messageReceived.onNext(.failure(error))

        // Then
        let expectedMobileBulkChange = MobileBulkChange(
            state: .init(requestingBulkIDs: [sorcIDA]),
            action: .responseDataFailed(error: .receivedInvalidData)
        )
    }

    func test_requestMobilebulk_ifConnectedAndMessageIsEnqueuedAndReceivedMobilebulkResponse_itNotifiesResponseAndItSendsEnqueuedMessage() {
        // Given
        prepareConnected()

        sessionManager.requestBulk(mobileBulk1!)
        sessionManager.requestBulk(mobileBulk2!)

        var receivedMobileBulk: MobileBulkChange!
        _ = sessionManager.mobileBulkChange.subscribeNext { change in
            receivedMobileBulk = change
        }

        // When
        securityManager.messageReceived.onNext(.success(mobileBulkResponseMessage))

        // Then
        let bulkResponseMessage = try? BulkResponseMessage(rawData: Data([
            0x02, // protocol version
            0xBE, 0x2F, 0xEC, 0xAF, 0x73, 0x4B, 0x42, 0x52, 0x83, 0x12, 0x59, 0xD4, 0x77, 0x20, 0x0A, 0x20, // bulk id
            0x0C, 0x00, 0x00, 0x00, // anchor length, little endian uint32
            0x54, 0x75, 0x67, 0x65, 0x6E, 0x32, 0x43, 0x6F, 0x6E, 0x66, 0x69, 0x67, // anchor
            0x05, 0x00, 0x00, 0x00, // revision length, little endian uint32
            0x48, 0x65, 0x6C, 0x6C, 0x6F, // revision
            0x8C, 0x00, 0x00, 0x00 // message, uint32
        ]))
        let mobileBulkResponse = try? MobileBulkResponse(bulkResponseMessage: bulkResponseMessage!)

        let expectedMobileBulkChange = MobileBulkChange(
            state: .init(requestingBulkIDs: [sorcIDA]),
            action: .responseReceived(mobileBulkResponse!)
        )

        XCTAssertEqual(receivedMobileBulk!, expectedMobileBulkChange)

        let bulkTransmitMessage = try? BulkTransmitMessage(mobileBulk: mobileBulk2!)
        let expectedMessage = SorcMessage(
            id: SorcMessageID.bulkTransferRequest,
            payload: bulkTransmitMessage!
        )
        XCTAssertEqual(securityManager.sendMessageCalledWithMessage!, expectedMessage)
    }

    func test_requestServiceGrant_ifConnectedAndQueueIsFull_itDoesNotSendMessageAndItNotifiesNotAccepted() {
        // Given
        let configuration = SessionManager.Configuration(maximumEnqueuedMessages: 2)

        let sendHeartBeatsTimer: CreateTimer = { _ in self.defaultTimer() }

        let checkHeartbeatsResponseTimer: CreateTimer = { _ in self.defaultTimer() }

        sessionManager = SessionManager(securityManager: securityManager,
                                        configuration: configuration,
                                        sendHeartbeatsTimer: sendHeartBeatsTimer,
                                        checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer)
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

    func test_requestMobile_ifConnectedAndQueueIsFull_itDoesNotSendMessageAndItNotifiesNotAccepted() {
        // Given
        let configuration = SessionManager.Configuration(maximumEnqueuedMessages: 2)

        let sendHeartBeatsTimer: CreateTimer = { _ in self.defaultTimer() }

        let checkHeartbeatsResponseTimer: CreateTimer = { _ in self.defaultTimer() }

        sessionManager = SessionManager(securityManager: securityManager,
                                        configuration: configuration,
                                        sendHeartbeatsTimer: sendHeartBeatsTimer,
                                        checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer)
        prepareConnected()

        // added and instantly removed from queue
        sessionManager.requestBulk(mobileBulk2!)
        // enqueued and staying in queue
        sessionManager.requestBulk(mobileBulk1!)
        sessionManager.requestBulk(mobileBulk1!)
        // not accepted, queue is full
        sessionManager.requestBulk(mobileBulk2!)

        var receivedMobileBulkChange: MobileBulkChange!
        _ = sessionManager.mobileBulkChange.subscribeNext { change in
            receivedMobileBulkChange = change
        }

        // When
        sessionManager.requestBulk(mobileBulk1!)

        // Then
        let bulkTransmitMessage = try? BulkTransmitMessage(mobileBulk: mobileBulk1!)
        let unexpectedMessage = SorcMessage(
            id: SorcMessageID.bulkTransferRequest,
            payload: bulkTransmitMessage!
        )
        XCTAssertNotEqual(securityManager.sendMessageCalledWithMessage!, unexpectedMessage)

        let expectedMobieBulkChange = MobileBulkChange(
            state: .init(requestingBulkIDs: [sorcIDA, sorcIDA, sorcIDA]),
            action: .requestMobileBulk(bulkID: sorcIDA, accepted: false)
        )
        XCTAssertEqual(receivedMobileBulkChange, expectedMobieBulkChange)
    }

    func test_requestServiceGrant_ifNotConnected_itDoesNotSendMessage() {
        // Given
        // When
        sessionManager.requestServiceGrant(serviceGrantIDA)

        // Then
        XCTAssertNil(securityManager.sendMessageCalledWithMessage)
    }

    func test_requestMobileBulk_ifNotConnected_itDoesNotSendMessage() {
        // Given
        // When
        sessionManager.requestBulk(mobileBulk1!)

        // Then
        XCTAssertNil(securityManager.sendMessageCalledWithMessage)
    }

    func test_requestServiceGrant_ifNotConnected_itNotifiesNotConnectedError() {
        // Given
        var receivedServiceGrantChange: ServiceGrantChange!
        _ = sessionManager.serviceGrantChange.subscribeNext { change in
            receivedServiceGrantChange = change
        }

        // When
        sessionManager.requestServiceGrant(serviceGrantIDA)

        // Then
        let expectedServiceGrantChange = ServiceGrantChange(
            state: .init(requestingServiceGrantIDs: []),
            action: .requestFailed(.notConnected)
        )
        XCTAssertEqual(receivedServiceGrantChange!, expectedServiceGrantChange)
    }

    func test_requestMobileBulk_ifNotConnected_itNotifiesNotConnectedError() {
        // Given
        var receivedMobileBulk: MobileBulkChange!
        _ = sessionManager.mobileBulkChange.subscribeNext { change in
            receivedMobileBulk = change
        }

        // When
        sessionManager.requestBulk(mobileBulk1!)

        // Then
        let expectedMobileBulkChange = MobileBulkChange(
            state: .init(requestingBulkIDs: []),
            action: .requestFailed(bulkID: sorcIDA, error: .notConnected)
        )
        XCTAssertEqual(receivedMobileBulk!, expectedMobileBulkChange)
    }

    // MARK: Heart beat handling

    func test_checkHeartBeat_ifTimedOut_disconnects() {
        // Given
        let timeout = TimeInterval(1)
        let configuration = SessionManager.Configuration(heartbeatTimeout: timeout)

        let sendHeartBeatsTimer: CreateTimer = { _ in self.defaultTimer() }

        var checkHeartbeatHandler: (() -> Void)!
        let checkHeartbeatsResponseTimer: CreateTimer = { block in
            checkHeartbeatHandler = block
            return self.defaultTimer()
        }
        // start x seconds in the past where x = timeout
        let clock = SystemClockMock(currentNow: Date().addingTimeInterval(-timeout))
        sessionManager = SessionManager(securityManager: securityManager,
                                        configuration: configuration,
                                        sendHeartbeatsTimer: sendHeartBeatsTimer,
                                        checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer,
                                        systemClock: clock)

        prepareConnected()

        // When
        // Turn clock to now
        clock.currentNow = Date()
        checkHeartbeatHandler()

        // Then
        XCTAssertTrue(securityManager.disconnectCalled)
    }

    func test_checkHeartBeat_heartBeatWasSent_doesNotDisconnect() {
        // Given
        let timeout: TimeInterval = 5
        let configuration = SessionManager.Configuration(heartbeatTimeout: timeout)

        var sendHeartBeatHandler: (() -> Void)!
        let sendHeartBeatsTimer: CreateTimer = { block in
            sendHeartBeatHandler = block
            return self.defaultTimer()
        }

        var checkHeartbeatHandler: (() -> Void)!
        let checkHeartbeatsResponseTimer: CreateTimer = { block in
            checkHeartbeatHandler = block
            return self.defaultTimer()
        }

        // Instantiate sessionManager and prepare connection with "now" in the past
        let systemClock = SystemClockMock(currentNow: Date().addingTimeInterval(-timeout))
        sessionManager = SessionManager(securityManager: securityManager,
                                        configuration: configuration,
                                        sendHeartbeatsTimer: sendHeartBeatsTimer,
                                        checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer,
                                        systemClock: systemClock)

        prepareConnected()

        // Change "now" to be < heartbeatTimeout
        systemClock.currentNow = Date().addingTimeInterval(-timeout + 1)

        // Send heart beat and receive response (this will reset internal lastHeartbeatResponseDate of SessionManager to current "now")
        sendHeartBeatHandler()
        let sorcMessage = SorcMessage(id: .heartBeatResponse, payload: EmptyPayload())
        let result = Result.success(sorcMessage)
        securityManager.messageReceived.onNext(result)

        // Check heart beat
        checkHeartbeatHandler()

        XCTAssertFalse(securityManager.disconnectCalled)
    }

    func test_sendHeartBeat_ifConnectedAndWaitingForResponse_enquesHeartBeat() {
        // Given
        let configuration = SessionManager.Configuration(maximumEnqueuedMessages: 2)

        var sendHeartBeatHandler: (() -> Void)!
        let sendHeartBeatsTimer: CreateTimer = { block in
            sendHeartBeatHandler = block
            return self.defaultTimer()
        }

        let checkHeartbeatsResponseTimer: CreateTimer = { _ in self.defaultTimer() }

        sessionManager = SessionManager(securityManager: securityManager,
                                        configuration: configuration,
                                        sendHeartbeatsTimer: sendHeartBeatsTimer,
                                        checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer)
        prepareConnected()

        // Added to the queue, instantly removed and waiting for response
        sessionManager.requestServiceGrant(serviceGrantIDA)

        // When
        sendHeartBeatHandler() // trigger "heart beat send"
        // On receiving response
        securityManager.messageReceived.onNext(.success(serviceGrantAResponseMessage))

        // Then
        let expectedMessage = SorcMessage(
            id: SorcMessageID.heartBeatRequest,
            payload: DefaultMessage()
        )
        let lastMessagePassedToSecManager = securityManager.sendMessageCalledWithMessage!
        XCTAssertEqual(lastMessagePassedToSecManager, expectedMessage)
    }

    // MARK: - State preparation

    private func preparePhysicalConnecting() {
        sessionManager.connectToSorc(leaseToken: leaseTokenA, leaseTokenBlob: leaseTokenBlobA)
        securityManager.connectToSorcCalledWithArguments = nil
    }

    private func prepareChallengingConnecting() {
        preparePhysicalConnecting()
        securityManager.connectionChange.onNext(.init(
            state: .connecting(sorcID: sorcIDA, state: .challenging),
            action: .physicalConnectionEstablished(sorcID: sorcIDA)
        ))
    }

    private func prepareConnected() {
        prepareChallengingConnecting()
        securityManager.connectionChange.onNext(.init(
            state: .connected(sorcID: sorcIDA),
            action: .connectionEstablished(sorcID: sorcIDA)
        ))
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

    private func defaultTimer() -> RepeatingBackgroundTimer {
        return RepeatingBackgroundTimer(timeInterval: 1000, queue: .main)
    }

    private var mobileBulk1: MobileBulk? = {
        let metadata =
            """
            {\"revision\" : \"Hello\",
            \"anchor\" : \"Tugen2Config\",
            \"signature\" : \"MD4CHQCTDQjGXFF0ar2tVR2Og3Tc7sTQPrJTd3T\\/T\\/kMAh0AiKEE6SWqVl+zhATQsitq05wgqPlAo\\/G\\/KEb0YQ==\",
            \"deviceId\" : \"00000000-0000-0000-0000-000000000000\",
            \"firmwareVersion\" : \"0.8.69RC4\"}
            """
        let content = "AAAAAAUAAAAAAAAAAgACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

        return try? MobileBulk(bulkID: sorcIDA, type: .configBulk, metadata: metadata, content: content)
    }()

    private var mobileBulk2: MobileBulk? = {
        let metadata =
            """
            {\"revision\" : \"58fbf1b56958d47dd08987cba89554c430f2c8ca#000000\",
            \"anchor\" : \"KeyControlConfig\",
            \"signature\" : \"MD0CHQChf1SHoffCTG0a542RasrxCJLWW9MtroDfMocDAhx7DN3D82f6lVYxXCTJL5TUaseBtJTlC9abKQEC\",
            \"deviceId\" : \"00000000-0000-0000-0000-000000000000\",
            \"firmwareVersion\" : \"0.8.69RC4\"}
            """
        let content = "AAAAAAQAAAAAAAAAAQABAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAA=="

        return try? MobileBulk(bulkID: sorcIDA, type: .configBulk, metadata: metadata, content: content)
    }()
}
