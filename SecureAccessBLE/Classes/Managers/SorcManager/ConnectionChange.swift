//
//  ConnectionChange.swift
//  SecureAccessBLE
//
//  Created on 07.06.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

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

            /// Challenging state
            case challenging
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

        /// Connection with provided `SorcID` established
        case connectionEstablished(sorcID: SorcID)

        /// Connecting to provided `SorcID` failed with `ConnectingFailedError`
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)

        /// Disconnect
        case disconnect

        /// Connection lost with `ConnectionLostError`
        case connectionLost(error: ConnectionLostError)
    }
}

/// The errors that can occur if the connection attempt fails
public enum ConnectingFailedError: Error {
    /// Physical connecting failed
    case physicalConnectingFailed

    /// Challenge failed
    case challengeFailed

    /// BLOB is outdated
    case blobOutdated

    /// BLOB time check failed
    case invalidTimeFrame
}

/// The errors that can occur if the connection is lost
public enum ConnectionLostError: Error {
    /// Physical connection is lost
    case physicalConnectionLost

    /// Heartbeat has timed out
    case heartbeatTimedOut
}
