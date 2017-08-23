//
//  TransportConnectionChange.swift
//  SecureAccessBLE
//
//  Created by Torsten Lehmann on 22.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

import Foundation
import CommonUtils

/// Describes a change of connection state
struct TransportConnectionChange: ChangeType, Equatable {

    static func initialWithState(_ state: TransportConnectionChange.State) -> TransportConnectionChange {
        return TransportConnectionChange(state: state, action: .initial)
    }

    /// The state the connection can be in
    let state: State

    /// The action that led to the state
    let action: Action

    init(state: State, action: Action) {
        self.state = state
        self.action = action
    }

    static func ==(lhs: TransportConnectionChange, rhs: TransportConnectionChange) -> Bool {
        return lhs.state == rhs.state && lhs.action == rhs.action
    }
}

extension TransportConnectionChange {

    /// The state the connection can be in
    enum State: Equatable {
        case disconnected
        case connecting(sorcID: SorcID, state: ConnectingState)
        case connected(sorcID: SorcID)

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected): return true
            case let (.connecting(lSorcID, lState), .connecting(rSorcID, rState)):
                return lSorcID == rSorcID && lState == rState
            case let (.connected(lSorcID), .connected(rSorcID)): return lSorcID == rSorcID
            default:
                return false
            }
        }

        enum ConnectingState {
            case physical
            case requestingMTU
        }
    }
}

extension TransportConnectionChange {

    /// The action that led to the state
    enum Action: Equatable {
        case initial
        case connect(sorcID: SorcID)
        case physicalConnectionEstablished(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID)
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)
        case disconnect
        case connectionLost(error: ConnectionLostError)

        static func ==(lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial):
                return true
            case let (.connect(lSorcID), .connect(rSorcID)):
                return lSorcID == rSorcID
            case let (.physicalConnectionEstablished(lSorcID), .physicalConnectionEstablished(rSorcID)):
                return lSorcID == rSorcID
            case let (.connectionEstablished(lSorcID), .connectionEstablished(rSorcID)):
                return lSorcID == rSorcID
            case let (.connectingFailed(lError, lSorcID), .connectingFailed(rError, rSorcID)):
                return lError == rError && lSorcID == rSorcID
            case (.disconnect, .disconnect):
                return true
            case let (.connectionLost(lError), .connectionLost(rError)):
                return lError == rError
            default:
                return false
            }
        }
    }

    /// The errors that can occur if the connection attempt fails
    enum ConnectingFailedError {
        case physicalConnectingFailed
        case transportConnectingFailed
    }

    /// The errors that can occur if the connection is lost
    enum ConnectionLostError {
        case physicalConnectionLost
    }
}
