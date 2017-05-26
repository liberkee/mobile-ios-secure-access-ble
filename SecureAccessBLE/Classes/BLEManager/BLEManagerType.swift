//
//  BLEManagerType.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 24.05.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

public protocol BLEManagerType: class {

    /// Configuration ///

    /// The interval a heartbeat is sent to the SORC
    var heartbeatInterval: Double { get set }

    /// The duration to wait for a heartbeat response from the SORC
    var heartbeatTimeout: Double { get set }

    /// Getters ///

    var isPoweredOn: Bool { get }

    var isConnected: Bool { get }

    func hasSorcId(_ sorcId: String) -> Bool

    /// Actions ///

    /**
     Connects to a SORC

     - parameter leaseToken: The lease token for the SORC
     - parameter blob: The blob for the SORC
     */
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob)

    /**
     Disconnects from current SORC
     */
    func disconnect()

    /**
     Communicating connected SID with sending messages, that was builed from serviceGrant request with
     id as messages payload

     - parameter feature: defined features to identifier the target SidMessage id
     */
    func sendServiceGrantForFeature(_ feature: ServiceGrantFeature)

    //// Observables

    var connectedToSorc: PublishSubject<SID> { get }

    var failedConnectingToSorc: PublishSubject<(sorc: SID, error: Error?)> { get }

    var receivedServiceGrantTriggerForStatus: PublishSubject<(status: ServiceGrantTriggerStatus?, error: String?)> { get }

    var sorcDiscovered: PublishSubject<SID> { get }

    var sorcsLost: PublishSubject<[SID]> { get }

    var blobOutdated: PublishSubject<()> { get }

    var connected: BehaviorSubject<Bool> { get }

    var updatedState: PublishSubject<()> { get }

    var discoveredSorcs: BehaviorSubject<[SID]> { get }
}

public struct LeaseToken {

    let id: String
    let leaseId: String
    let sorcId: String
    let sorcAccessKey: String

    public init(id: String, leaseId: String, sorcId: String, sorcAccessKey: String) {
        self.id = id
        self.leaseId = leaseId
        self.sorcId = sorcId
        self.sorcAccessKey = sorcAccessKey
    }
}

public struct LeaseTokenBlob {

    let messageCounter: Int
    let data: String

    public init(messageCounter: Int, data: String) {
        self.messageCounter = messageCounter
        self.data = data
    }
}

// enum LinkType {
//    case ble
//    case bleTestSORC
// }
//
// enum SORCErrorCode {
//    case noError
//    case linkLayerError
//    case bluetoothInterfaceGone
//    case securityError
//    case remoteClose
//    case remoteGone
//    case autoReconnectFail
//    case connectFinalFail
// }
//
// enum InterfaceErrorCode {
//    case noError
//    case unavailable
//    case permissionError
//    case deviceDeactivated
//    case performanceWarning
//    case serviceGrantQueueLimitReached
//    case deviceError
// }
//
// enum SORCStatusCode {
//    case unavailable
//    case searching
//    case searchingOverdue
//    case available
//    case connecting
//    case CRAMStage
//    case BLOBTransfer
//    case connected
//    case disconnecting
//    case removed
//    case error
// }
//
// enum AutoConnectStatus {
//    case disabled
//    case enabled
//    case paused
// }
