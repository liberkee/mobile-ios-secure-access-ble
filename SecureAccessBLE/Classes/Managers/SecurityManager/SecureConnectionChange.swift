//
//  SecureConnectionChange.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// Describes a change of connection state
public struct SecureConnectionChange: ChangeType, Equatable {

    public static func initialWithState(_ state: SecureConnectionChange.State) -> SecureConnectionChange {
        return SecureConnectionChange(state: state, action: .initial)
    }

    /// The state the connection can be in
    public let state: State

    /// The action that led to the state
    public let action: Action

    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }

    public static func ==(lhs: SecureConnectionChange, rhs: SecureConnectionChange) -> Bool {
        return lhs.state == rhs.state && lhs.action == rhs.action
    }
}

extension SecureConnectionChange {

    /// The state the connection can be in
    public enum State: Equatable {
        case disconnected
        case connecting(sorcID: SorcID, state: ConnectingState)
        case connected(sorcID: SorcID)

        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected): return true
            case let (.connecting(lSorcID, lState), .connecting(rSorcID, rState)):
                return lSorcID == rSorcID && lState == rState
            case let (.connected(lSorcID), .connected(rSorcID)):
                return lSorcID == rSorcID
            default:
                return false
            }
        }

        public enum ConnectingState {
            case physical
            case transport
            case challenging
        }
    }
}

extension SecureConnectionChange {

    /// The action that led to the state
    public enum Action: Equatable {
        case initial
        case connect(sorcID: SorcID)
        case physicalConnectionEstablished(sorcID: SorcID)
        case transportConnectionEstablished(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID)
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)
        case disconnect
        case connectionLost(error: ConnectionLostError)

        public static func ==(lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial):
                return true
            case let (.connect(lSorcID), .connect(rSorcID)):
                return lSorcID == rSorcID
            case let (.physicalConnectionEstablished(lSorcID), .physicalConnectionEstablished(rSorcID)):
                return lSorcID == rSorcID
            case let (.transportConnectionEstablished(lSorcID), .transportConnectionEstablished(rSorcID)):
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
    public enum ConnectingFailedError: Error {
        case physicalConnectingFailed
        case transportConnectingFailed
        case challengeFailed
        case blobOutdated
    }

    /// The errors that can occur if the connection is lost
    public enum ConnectionLostError: Error {
        case physicalConnectionLost
    }
}
