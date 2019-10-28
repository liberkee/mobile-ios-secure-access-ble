//
//  TransportConnectionChange.swift
//  SecureAccessBLE
//
//  Created on 23.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

/// Describes a change of connection state
struct TransportConnectionChange: ChangeType, Equatable {
    static func initialWithState(_ state: TransportConnectionChange.State) -> TransportConnectionChange {
        return TransportConnectionChange(state: state, action: .initial)
    }

    /// The state the connection can be in
    let state: State

    /// The action that led to the state
    let action: Action
}

extension TransportConnectionChange {
    /// The state the connection can be in
    enum State: Equatable {
        case disconnected
        case connecting(sorcID: SorcID)
        case connected(sorcID: SorcID)
    }
}

extension TransportConnectionChange {
    /// The action that led to the state
    enum Action: Equatable {
        case initial
        case connect(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID)
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)
        case disconnect
        case connectionLost(error: ConnectionLostError)
    }

    /// The errors that can occur if the connection attempt fails
    enum ConnectingFailedError: Error {
        case physicalConnectingFailed
    }

    /// The errors that can occur if the connection is lost
    enum ConnectionLostError: Error {
        case physicalConnectionLost
    }
}
