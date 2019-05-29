//
//  SecureConnectionChange.swift
//  SecureAccessBLE
//
//  Created on 07.06.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

/// Describes a change of connection state
struct SecureConnectionChange: ChangeType, Equatable {
    static func initialWithState(_ state: SecureConnectionChange.State) -> SecureConnectionChange {
        return SecureConnectionChange(state: state, action: .initial)
    }

    /// The state the connection can be in
    let state: State

    /// The action that led to the state
    let action: Action
}

extension SecureConnectionChange {
    /// The state the connection can be in
    enum State: Equatable {
        case disconnected
        case connecting(sorcID: SorcID, state: ConnectingState)
        case connected(sorcID: SorcID)

        enum ConnectingState {
            case physical
            case transport
            case challenging
        }
    }
}

extension SecureConnectionChange {
    /// The action that led to the state
    enum Action: Equatable {
        case initial
        case connect(sorcID: SorcID)
        case physicalConnectionEstablished(sorcID: SorcID)
        case transportConnectionEstablished(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID)
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)
        case disconnect
        case connectionLost(error: ConnectionLostError)
    }

    /// The errors that can occur if the connection attempt fails
    enum ConnectingFailedError: Error {
        case physicalConnectingFailed
        case invalidMTUResponse
        case challengeFailed
        case blobOutdated
        case invalidTimeFrame
    }

    /// The errors that can occur if the connection is lost
    enum ConnectionLostError: Error {
        case physicalConnectionLost
    }
}
