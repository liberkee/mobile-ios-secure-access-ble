//
//  SessionManager.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Sends and receives SORC messages. Handles encryption/decryption.
class SessionManager: SessionManagerType {

    let connectionChange = ChangeSubject<ConnectionChange>(state: .disconnected)

    let serviceGrantResultReceived = PublishSubject<ServiceGrantResult>()

    var heartbeatInterval: Double = 2000.0
    var heartbeatTimeout: Double = 6000.0

    private let securityManager: SecurityManagerType
    private let disposeBag = DisposeBag()

    private var sendHeartbeatsTimer: Timer?
    private var checkHeartbeatsResponseTimer: Timer?
    private var lastHeartbeatResponseDate = Date()
    private var lastMessageSent: SorcMessage?
    private var waitingForResponse = false
    private var actionLeadingToDisconnect: ConnectionChange.Action?

    private let maximumEnqueuedMessages = 3
    private lazy var messageQueue: BoundedQueue<SorcMessage> = {
        BoundedQueue(maximumElements: self.maximumEnqueuedMessages)
    }()

    init(securityManager: SecurityManagerType) {
        self.securityManager = securityManager

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
            connectionChange.onNext(.init(state: .connecting(sorcID: leaseToken.sorcID, state: .physical),
                                          action: .connect(sorcID: leaseToken.sorcID)))
        }

        securityManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    func disconnect() {
        disconnect(withAction: .disconnect)
    }

    func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        guard case .connected = connectionChange.state else { return }

        let message = SorcMessage(
            id: SorcMessageID.serviceGrant,
            payload: ServiceGrantRequest(serviceGrantID: serviceGrantID)
        )
        do {
            try enqueueMessage(message)
        } catch {
            serviceGrantResultReceived.onNext(.failure(.queueIsFull))
        }
    }

    // MARK: - Private methods

    private func enqueueMessage(_ message: SorcMessage) throws {
        NSLog("BLA: enqueueMessage: \(message.id)")
        try messageQueue.enqueue(message)
        sendNextMessageIfPossible()
    }

    private func sendNextMessageIfPossible() {
        guard !waitingForResponse, let message = messageQueue.dequeue() else { return }

        lastMessageSent = message
        waitingForResponse = true
        securityManager.sendMessage(message)
    }

    private func disconnect(withAction action: ConnectionChange.Action) {
        switch connectionChange.state {
        case .connecting, .connected: break
        default: return
        }
        NSLog("BLA handleConnectionChange disconnect(withAction")
        actionLeadingToDisconnect = action
        securityManager.disconnect()
    }

    private func reset() {
        stopSendingHeartbeat()
        lastMessageSent = nil
        waitingForResponse = false
        actionLeadingToDisconnect = nil
        messageQueue = BoundedQueue(maximumElements: maximumEnqueuedMessages)
    }

    private func scheduleHeartbeatTimers() {
        NSLog("BLA: scheduleHeartbeatTimers")
        sendHeartbeatsTimer = Timer.scheduledTimer(
            timeInterval: heartbeatInterval / 1000,
            target: self,
            selector: #selector(SessionManager.startSendingHeartbeat),
            userInfo: nil,
            repeats: true
        )
        checkHeartbeatsResponseTimer = Timer.scheduledTimer(
            timeInterval: heartbeatTimeout / 1000,
            target: self,
            selector: #selector(SessionManager.checkOutHeartbeatResponse),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func startSendingHeartbeat() {
        guard !waitingForResponse else { return }
        NSLog("BLA startSendingHeartbeat: \(Date())")
        let message = SorcMessage(id: SorcMessageID.heartBeatRequest, payload: MTUSize())
        try? enqueueMessage(message)
    }

    private func stopSendingHeartbeat() {
        NSLog("BLA stopSendingHeartbeat")
        sendHeartbeatsTimer?.invalidate()
        checkHeartbeatsResponseTimer?.invalidate()
    }

    @objc func checkOutHeartbeatResponse() {
        NSLog("BLA checkOutHeartbeatResponse")
        if (lastHeartbeatResponseDate.timeIntervalSinceNow + heartbeatTimeout / 1000) < 0 {
            NSLog("checkOutHeartbeatResponse timedout")
            disconnect(withAction: .connectionLost(error: .heartbeatTimedOut))
        }
    }

    private func handleSecureConnectionChange(_ secureChange: SecureConnectionChange) {

        switch secureChange.state {
        case let .connecting(securitySorcID, secureConnectingState):
            switch secureConnectingState {
            case .physical: break
            case .transport:
                guard case let .connecting(sorcID, .physical) = connectionChange.state, sorcID == securitySorcID else {
                    return
                }
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .transport),
                                              action: .physicalConnectionEstablished(sorcID: sorcID)))
            case .challenging:
                guard case let .connecting(sorcID, .transport) = connectionChange.state, sorcID == securitySorcID else {
                    return
                }
                connectionChange.onNext(.init(state: .connecting(sorcID: sorcID, state: .challenging),
                                              action: .transportConnectionEstablished(sorcID: sorcID)))
            }
        case let .connected(sorcID):
            guard connectionChange.state == .connecting(sorcID: sorcID, state: .challenging) else { return }
            connectionChange.onNext(.init(state: .connected(sorcID: sorcID),
                                          action: .connectionEstablished(sorcID: sorcID)))
            scheduleHeartbeatTimers()
        case .disconnected:
            if connectionChange.state == .disconnected { return }
            let actionLeadingToDisconnect = self.actionLeadingToDisconnect
            reset()
            if let action = actionLeadingToDisconnect {
                connectionChange.onNext(.init(state: .disconnected, action: action))
                return
            }
            NSLog("BLA handleConnectionChange disconnected")
            switch secureChange.action {
            case let .connectingFailed(sorcID, secureConnectingFailedError):
                let error = ConnectingFailedError(secureConnectingFailedError: secureConnectingFailedError)
                connectionChange.onNext(.init(state: .disconnected,
                                              action: .connectingFailed(sorcID: sorcID, error: error)))
            case .disconnect:
                connectionChange.onNext(.init(state: .disconnected, action: .disconnect))
            case let .connectionLost(secureConnectionLostError):
                let error = ConnectionLostError(secureConnectionLostError: secureConnectionLostError)
                connectionChange.onNext(.init(state: .disconnected, action: .connectionLost(error: error)))
            default: break
            }
        }
    }

    private func handleMessageSent(result: Result<SorcMessage>) {
        // TODO: PLAM-959 do we need this?
        // When it goes wrong, do we retry or send the next one or close connection?
        switch result {
        case .success:
            NSLog("BLA sent message")
        case .failure:
            NSLog("BLA sent message error")
        }
    }

    private func handleMessageReceived(result: Result<SorcMessage>) {
        guard case let .connected(sorcID) = connectionChange.state else { return }

        waitingForResponse = false

        guard case let .success(message) = result else {
            if lastMessageSent?.id == .serviceGrant {
                serviceGrantResultReceived.onNext(.failure(.receivedInvalidData))
            }
            return
        }

        NSLog("BLA handleMessageReceived: \(message.id)")

        switch message.id {
        case .heartBeatResponse:
            handleSorcResponded()
        case .serviceGrantTrigger:
            guard let response = ServiceGrantResponse(sorcID: sorcID, message: message) else {
                serviceGrantResultReceived.onNext(.failure(.receivedInvalidData))
                return
            }
            handleSorcResponded()
            serviceGrantResultReceived.onNext(.success(response))
        default:
            return
        }

        sendNextMessageIfPossible()
    }

    private func handleSorcResponded() {
        lastHeartbeatResponseDate = Date()
        NSLog("BLA: handleSorcResponded \(lastHeartbeatResponseDate)")
        checkHeartbeatsResponseTimer?.fireDate = lastHeartbeatResponseDate.addingTimeInterval(heartbeatTimeout / 1000)
    }
}

// MARK: - Error extensions

private extension ConnectingFailedError {

    init(secureConnectingFailedError: SecureConnectionChange.ConnectingFailedError) {
        switch secureConnectingFailedError {
        case .physicalConnectingFailed:
            self = .physicalConnectingFailed
        case .transportConnectingFailed:
            self = .transportConnectingFailed
        case .challengeFailed:
            self = .challengeFailed
        case .blobOutdated:
            self = .blobOutdated
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

    init?(sorcID: SorcID, message: SorcMessage) {
        self.sorcID = sorcID

        // TODO: PLAM-959 test this

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
