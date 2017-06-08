//
//  ConnectionChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 07.06.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

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
        case connecting(sorcId: String)
        case connected(sorcId: String)
    }

    /// The action that led to the state
    public enum Action {
        // external
        case connect
        case disconnect
        // internal
        case initial
        case connectionEstablished(sorcId: String, rssi: Int)
        case connectingFailed(error: ConnectingFailedError, sorcId: String, rssi: Int)
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
    case unknown
}
