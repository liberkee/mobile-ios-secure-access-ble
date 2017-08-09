//
//  ConnectionChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 07.06.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Describes a change of connection state
public struct ConnectionChange: ChangeType {

    /// The state the connection can be in
    public enum State {
        case disconnected
        case connecting(sorcID: SorcID)
        case connected(sorcID: SorcID)
    }

    /// The action that led to the state
    public enum Action {
        // external
        case connect
        case disconnect
        // internal
        case initial
        case connectionEstablished(sorcID: SorcID, rssi: Int)
        case connectingFailed(error: ConnectingFailedError, sorcID: SorcID, rssi: Int)
        case connectionLost(error: ConnectionLostError)
    }

    public static func initialWithState(_ state: ConnectionChange.State) -> ConnectionChange {
        return ConnectionChange(state: state, action: .initial)
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
