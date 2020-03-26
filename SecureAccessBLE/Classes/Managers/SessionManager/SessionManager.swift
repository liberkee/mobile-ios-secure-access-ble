//
//  SessionManager.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Sends and receives service messages. Manages heartbeats.
class SessionManager: SessionManagerType {
    let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    let serviceGrantChange = ChangeSubject<ServiceGrantChange>(state: .init(requestingServiceGrantIDs: []))

    private let securityManager: SecurityManagerType
    private let configuration: Configuration

    private let disposeBag = DisposeBag()

    private var sendHeartbeatsTimer: RepeatingBackgroundTimer?
    private var checkHeartbeatsResponseTimer: RepeatingBackgroundTimer?
    private var lastHeartbeatResponseDate: Date

    /// Used to know how to handle a response based on what we sent before
    private var lastMessageSent: SorcMessage?

    private var waitingForResponse = false

    /// Used to know what action we need to send out after disconnect on lower layers happened
    private var actionLeadingToDisconnect: ConnectionChange.Action?

    private lazy var messageQueue: BoundedQueue<SorcMessage> = {
        BoundedQueue(maximumElements: self.configuration.maximumEnqueuedMessages)
    }()

    private let systemClock: SystemClockType

    init(securityManager: SecurityManagerType,
         configuration: Configuration = Configuration(),
         sendHeartbeatsTimer: CreateTimer,
         checkHeartbeatsResponseTimer: CreateTimer,
         systemClock: SystemClockType = SystemClock()) {
        self.securityManager = securityManager
        self.configuration = configuration
        self.systemClock = systemClock
        lastHeartbeatResponseDate = systemClock.now()
        self.sendHeartbeatsTimer = sendHeartbeatsTimer(sendHeartbeat)
        self.checkHeartbeatsResponseTimer = checkHeartbeatsResponseTimer(checkOutHeartbeatResponse)

        securityManager.connectionChange.subscribeNext { [weak self] change in
            self?.handleSecureConnectionChange(change)
        }
        .disposed(by: disposeBag)

        securityManager.messageSent.subscribeNext { [weak self] result in
            self?.handleMessageSent(result: result)
        }
        .disposed(by: disposeBag)

        securityManager.messageReceived.subscribeNext { [weak self] result in
            self?.handleMessageReceived(result: result)
        }
        .disposed(by: disposeBag)
    }

    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        guard connectionChange.state == .disconnected
            || connectionChange.state == .connecting(sorcID: leaseToken.sorcID, state: .physical)
        else { return }

        if connectionChange.state == .disconnected {
            connectionChange.onNext(.init(
                state: .connecting(sorcID: leaseToken.sorcID, state: .physical),
                action: .connect(sorcID: leaseToken.sorcID)
            ))
        }

        securityManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        guard case .connected = connectionChange.state else {
            applyServiceGrantChangeAction(.requestFailed(.notConnected))
            return
        }

        let message = SorcMessage(
            id: SorcMessageID.serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantID)
        )
        let accepted: Bool
        do {
            try enqueueMessage(message)
            accepted = true
        } catch {
            accepted = false
        }
        applyServiceGrantChangeAction(.requestServiceGrant(id: serviceGrantID, accepted: accepted))
    }

    // MARK: - Private methods -

    private func reset() {
        stopSendingHeartbeat()
        lastMessageSent = nil
        waitingForResponse = false
        actionLeadingToDisconnect = nil
        messageQueue.clear()
        applyServiceGrantChangeAction(.reset)
    }

    // MARK: - Connection handling

    private func disconnect(withAction action: ConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        actionLeadingToDisconnect = action
        securityManager.disconnect()
    }

    private func handleSecureConnectionChange(_ secureChange: SecureConnectionChange) {
        switch secureChange.state {
        case let .connecting(securitySorcID, secureConnectingState):
            handleSecureConnectionChangeConnecting(
                securitySorcID: securitySorcID,
                secureConnectingState: secureConnectingState
            )
        case let .connected(sorcID):
            handleSecureConnectionChangeConnected(sorcID: sorcID)
        case .disconnected:
            handleSecureConnectionChangeDisconnected(secureChangeAction: secureChange.action)
        }
    }

    private func handleSecureConnectionChangeConnecting(
        securitySorcID: SorcID,
        secureConnectingState: SecureConnectionChange.State.ConnectingState
    ) {
        switch secureConnectingState {
        case .physical:
            break
        case .challenging:
            guard case let .connecting(sorcID, .physical) = connectionChange.state, sorcID == securitySorcID else {
                return
            }
            connectionChange.onNext(.init(
                state: .connecting(sorcID: sorcID, state: .challenging),
                action: .physicalConnectionEstablished(sorcID: sorcID)
            ))
        }
    }

    private func handleSecureConnectionChangeConnected(sorcID: SorcID) {
        guard connectionChange.state == .connecting(sorcID: sorcID, state: .challenging) else { return }
        connectionChange.onNext(.init(
            state: .connected(sorcID: sorcID),
            action: .connectionEstablished(sorcID: sorcID)
        ))
        scheduleHeartbeatTimers()
    }

    private func handleSecureConnectionChangeDisconnected(secureChangeAction: SecureConnectionChange.Action) {
        if connectionChange.state == .disconnected { return }
        let actionLeadingToDisconnect = self.actionLeadingToDisconnect
        reset()
        if let action = actionLeadingToDisconnect {
            connectionChange.onNext(.init(
                state: .disconnected,
                action: action
            ))
            return
        }
        switch secureChangeAction {
        case let .connectingFailed(sorcID, secureConnectingFailedError):
            let error = ConnectingFailedError(secureConnectingFailedError: secureConnectingFailedError)
            connectionChange.onNext(.init(
                state: .disconnected,
                action: .connectingFailed(sorcID: sorcID, error: error)
            ))
        case .disconnect:
            connectionChange.onNext(.init(
                state: .disconnected,
                action: .disconnect
            ))
        case let .connectionLost(secureConnectionLostError):
            let error = ConnectionLostError(secureConnectionLostError: secureConnectionLostError)
            connectionChange.onNext(.init(
                state: .disconnected,
                action: .connectionLost(error: error)
            ))
        default: break
        }
    }

    // MARK: - Message handling

    private func enqueueMessage(_ message: SorcMessage) throws {
        try messageQueue.enqueue(message)
        sendNextMessageIfPossible()
    }

    private func sendNextMessageIfPossible() {
        guard !waitingForResponse, let message = messageQueue.dequeue() else { return }

        lastMessageSent = message
        waitingForResponse = true
        securityManager.sendMessage(message)
    }

    // TODO: Not called as described in comments on `messageSent` property in SecurityManager
    private func handleMessageSent(result: Result<SorcMessage>) {
        guard case .connected = connectionChange.state,
            case .failure = result,
            waitingForResponse else { return }

        waitingForResponse = false

        if lastMessageSent?.id == .serviceGrant {
            applyServiceGrantChangeAction(.requestFailed(.sendingFailed))
        }
        lastMessageSent = nil
    }

    private func handleMessageReceived(result: Result<SorcMessage>) {
        guard case let .connected(sorcID) = connectionChange.state,
            waitingForResponse else { return }

        waitingForResponse = false

        guard case let .success(message) = result else {
            if lastMessageSent?.id == .serviceGrant {
                applyServiceGrantChangeAction(.requestFailed(.receivedInvalidData))
            }
            lastMessageSent = nil
            return
        }

        switch message.id {
        case .heartBeatResponse:
            resetLastHeartBeatResponseDate()
        case .serviceGrantTrigger:
            guard let response = ServiceGrantResponse(sorcID: sorcID, message: message) else {
                applyServiceGrantChangeAction(.requestFailed(.receivedInvalidData))
                return
            }
            resetLastHeartBeatResponseDate()
            applyServiceGrantChangeAction(.responseReceived(response))
        default:
            return
        }

        sendNextMessageIfPossible()
    }

    private func applyServiceGrantChangeAction(_ action: ServiceGrantChange.Action) {
        switch action {
        case .initial: return
        case let .requestServiceGrant(serviceGrantID, accepted):
            var ids = serviceGrantChange.state.requestingServiceGrantIDs
            if accepted {
                ids.append(serviceGrantID)
            }
            let state = ServiceGrantChange.State(requestingServiceGrantIDs: ids)
            serviceGrantChange.onNext(.init(
                state: state,
                action: .requestServiceGrant(id: serviceGrantID, accepted: accepted)
            ))
        case let .responseReceived(response):
            var ids = serviceGrantChange.state.requestingServiceGrantIDs
            ids.remove(at: 0)
            let state = ServiceGrantChange.State(requestingServiceGrantIDs: ids)
            serviceGrantChange.onNext(.init(
                state: state,
                action: .responseReceived(response)
            ))
        case let .requestFailed(error):
            applyServiceGrantRequestFailed(error: error)
        case .reset:
            let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
            serviceGrantChange.onNext(.init(
                state: state,
                action: .reset
            ))
        }
    }

    private func applyServiceGrantRequestFailed(error: ServiceGrantChange.Error) {
        messageQueue.clear()
        if [.sendingFailed, .receivedInvalidData].contains(error) {
            sendHeartbeat()
        }
        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
        serviceGrantChange.onNext(.init(state: state, action: .requestFailed(error)))
    }

    // MARK: - Heartbeat handling

    private func scheduleHeartbeatTimers() {
        sendHeartbeatsTimer?.resume()
        lastHeartbeatResponseDate = systemClock.now()
        checkHeartbeatsResponseTimer?.resume()
    }

    @objc func sendHeartbeat() {
        let message = SorcMessage(id: SorcMessageID.heartBeatRequest, payload: DefaultMessage())
        do {
            try enqueueMessage(message)
            HSMLog(message: "Enqueued heartbeat message", level: .verbose)
        } catch {
            HSMLog(message: "Could not enqueue heartbeat message", level: .warning)
        }
    }

    private func stopSendingHeartbeat() {
        sendHeartbeatsTimer?.suspend()
        checkHeartbeatsResponseTimer?.suspend()
    }

    @objc func checkOutHeartbeatResponse() {
        let offset = lastHeartbeatResponseDate.timeIntervalSince(systemClock.now()) + configuration.heartbeatTimeout
        if offset < 0 {
            disconnect(withAction: .connectionLost(error: .heartbeatTimedOut))
        }
    }

    private func resetLastHeartBeatResponseDate() {
        lastHeartbeatResponseDate = systemClock.now()
    }
}

// MARK: - Error extensions

private extension ConnectingFailedError {
    init(secureConnectingFailedError: SecureConnectionChange.ConnectingFailedError) {
        switch secureConnectingFailedError {
        case .physicalConnectingFailed:
            self = .physicalConnectingFailed
        case .challengeFailed:
            self = .challengeFailed
        case .blobOutdated:
            self = .blobOutdated
        case .invalidTimeFrame:
            self = .invalidTimeFrame
        }
    }
}

private extension ConnectionLostError {
    init(secureConnectionLostError: SecureConnectionChange.ConnectionLostError) {
        switch secureConnectionLostError {
        case .physicalConnectionLost:
            self = .physicalConnectionLost
        }
    }
}

// MARK: - ServiceGrantResponse mapping

extension ServiceGrantResponse {
    // TODO: PLAM-1568 Test this
    init?(sorcID: SorcID, message: SorcMessage) {
        self.sorcID = sorcID

        let messageData = message.message

        var idByteArray = [UInt8](repeating: 0x0, count: 2)
        messageData.copyBytes(to: &idByteArray, from: 0 ..< 2)
        serviceGrantID = UInt16(idByteArray[0])

        var statusByteArray = [UInt8](repeating: 0x0, count: 1)
        messageData.copyBytes(to: &statusByteArray, from: 2 ..< 3)
        guard let status = ServiceGrantResponse.Status(rawValue: statusByteArray[0]) else { return nil }
        self.status = status

        guard messageData.count > 3 else {
            responseData = ""
            return
        }
        let messageData2 = messageData.subdata(in: 3 ..< messageData.count)
        guard let string = String(data: messageData2, encoding: .ascii) else { return nil }
        responseData = string.trimmingCharacters(in: CharacterSet.controlCharacters)
    }
}
