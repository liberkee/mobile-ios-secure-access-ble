//
//  ConnectionChange.swift
//  SecureAccessBLE
//
//  Created on 07.06.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// Describes a change of connection state
public struct ConnectionChange: ChangeType, Equatable {
    /// The state the connection can be in
    public let state: State

    /// The action that led to the state
    public let action: Action

    /// :nodoc:
    public static func initialWithState(_ state: ConnectionChange.State) -> ConnectionChange {
        return ConnectionChange(state: state, action: .initial)
    }

    /// :nodoc:
    public static func == (lhs: ConnectionChange, rhs: ConnectionChange) -> Bool {
        return lhs.state == rhs.state && lhs.action == rhs.action
    }

    /// :nodoc:
    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

extension ConnectionChange {
    /// The state the connection can be in
    public enum State: Equatable {
        /// Disconnected
        case disconnected

        /// Connecting to a specific `SorcID` in the current `ConnectingState`
        case connecting(sorcID: SorcID, state: ConnectingState)

        /// Connected to a specific `SorcID`
        case connected(sorcID: SorcID)

        /// The state when connecting to a SORC
        public enum ConnectingState {
            /// Physical state
            case physical

            /// Transport state
            case transport

            /// Challenging state
            case challenging
        }

        /// :nodoc:
        public static func == (lhs: State, rhs: State) -> Bool {
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
    }
}

extension ConnectionChange {
    /// The action that led to the state
    public enum Action: Equatable {
        /// The initial action which is sent on `subscribe`
        case initial

        /// Connect to provided `SorcID`
        case connect(sorcID: SorcID)

        /// Physical connection with provided `SorcID` established
        case physicalConnectionEstablished(sorcID: SorcID)

        /// Transport connection with provided `SorcID` established
        case transportConnectionEstablished(sorcID: SorcID)

        /// Connection with provided `SorcID` established
        case connectionEstablished(sorcID: SorcID)

        /// Connecting to provided `SorcID` failed with `ConnectingFailedError`
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)

        /// Disconnect
        case disconnect

        /// Connection lost with `ConnectionLostError`
        case connectionLost(error: ConnectionLostError)

        /// :nodoc:
        public static func == (lhs: Action, rhs: Action) -> Bool {
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
}

/// The errors that can occur if the connection attempt fails
public enum ConnectingFailedError: Error {
    /// Physical connecting failed
    case physicalConnectingFailed

    /// Invalid MTU response
    case invalidMTUResponse

    /// Challenge failed
    case challengeFailed

    /// BLOB is outdated
    case blobOutdated
}

/// The errors that can occur if the connection is lost
public enum ConnectionLostError: Error {
    /// Physical connection is lost
    case physicalConnectionLost

    /// Heartbeat has timed out
    case heartbeatTimedOut
}
