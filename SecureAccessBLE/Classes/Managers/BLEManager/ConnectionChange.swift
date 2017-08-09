//
//  ConnectionChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 07.06.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

public struct DiscoveryChange: ChangeType {

    public let state: Set<SorcID>
    public let action: Action

    public static func initialWithState(_ state: Set<SorcID>) -> DiscoveryChange {
        return DiscoveryChange(state: state, action: .initial)
    }

    public enum Action {
        case initial
        case sorcDiscovered(SorcID)
        case sorcsLost(Set<SorcID>)
        case disconnectSorc(SorcID)
        case sorcDisconnected(SorcID)
        case sorcsReset
    }
}

extension DiscoveryChange: Equatable {

    public static func ==(lhs: DiscoveryChange, rhs: DiscoveryChange) -> Bool {
        return lhs.state == rhs.state
            && lhs.action == rhs.action
    }
}

extension DiscoveryChange.Action: Equatable {

    public static func ==(lhs: DiscoveryChange.Action, rhs: DiscoveryChange.Action) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial): return true
        case let (.sorcDiscovered(lSorcID), .sorcDiscovered(rSorcID)) where lSorcID == rSorcID: return true
        case let (.sorcsLost(lSorcIDs), .sorcsLost(rSorcIDs)) where lSorcIDs == rSorcIDs: return true
        case let (.disconnectSorc(lSorcID), .disconnectSorc(rSorcID)) where lSorcID == rSorcID: return true
        case let (.sorcDisconnected(lSorcID), .sorcDisconnected(rSorcID)) where lSorcID == rSorcID: return true
        case (.sorcsReset, .sorcsReset): return true
        default: return false
        }
    }
}

/// Describes a change of connection state
public struct ConnectionChange {

    // Possible state transitions (other transitions have no observable result, i.e. <no change>)
    //                -initial->               (disconnected)
    // (disconnected) -connect->               (connecting)
    // (disconnected) -disconnect->            <no change>
    // (connecting)   -connect->               <no change>
    // (connecting)   -disconnect->            (disconnected)
    // (connecting)   -connectionEstablished-> (connected)
    // (connecting)   -connectingFailed->      (disconnected)
    // (connected)    -connect->               <no change>
    // (connected)    -disconnect->            (disconnected)
    // (connected)    -connectionLost->        (disconnected)

    /// The state the connection can be in
    public enum State {
        case disconnected
        case connecting(sorcId: SorcID)
        case connected(sorcId: SorcID)
    }

    /// The action that led to the state
    public enum Action {
        // external
        case connect
        case disconnect
        // internal
        case initial
        case connectionEstablished(sorcId: SorcID, rssi: Int)
        case connectingFailed(error: ConnectingFailedError, sorcId: SorcID, rssi: Int)
        case connectionLost(error: ConnectionLostError)
    }

    /// The state the connection can be in
    public let state: State

    /// The action that led to the state
    public let action: Action

    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

/// The errors that can occur if the connection attempt fails
public enum ConnectingFailedError {
    case blobOutdated
    case unknown
}

/// The errors that can occur if the connection is lost
public enum ConnectionLostError {
    case heartbeatTimedOut
    case bluetoothOff
    case unknown
}
