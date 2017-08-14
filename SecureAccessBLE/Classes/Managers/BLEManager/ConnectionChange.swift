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
public struct ConnectionChange: ChangeType, Equatable {

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

    public static func ==(lhs: ConnectionChange, rhs: ConnectionChange) -> Bool {
        return lhs.state == rhs.state && lhs.action == rhs.action
    }
}

extension ConnectionChange {

    /// The state the connection can be in
    public enum State: Equatable {
        case disconnected
        case connecting(sorcID: SorcID, state: ConnectingState)
        case connected(sorcID: SorcID)

        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected): return true
            case let (.connecting(lSorcID, lState), .connecting(rSorcID, rState))
                where lSorcID == rSorcID && lState == rState: return true
            case let (.connected(lSorcID), .connected(rSorcID)) where lSorcID == rSorcID:
                return true
            default:
                return false
            }
        }

        public enum ConnectingState {
            case physical
            case requestingMTU
            case challenging
        }
    }
}

extension ConnectionChange {

    /// The action that led to the state
    public enum Action: Equatable {
        case initial
        case connect(sorcID: SorcID)
        case physicalConnectionEstablished(sorcID: SorcID)
        case mtuRequested(sorcID: SorcID)
        case connectionEstablished(sorcID: SorcID)
        case connectingFailed(sorcID: SorcID, error: ConnectingFailedError)
        case disconnect
        case connectionLost(error: ConnectionLostError)

        public static func ==(lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial): return true
            case let (.connect(lSorcID), .connect(rSorcID)) where lSorcID == rSorcID: return true
            case let (.physicalConnectionEstablished(lSorcID), .physicalConnectionEstablished(rSorcID))
                where lSorcID == rSorcID: return true
            case let (.mtuRequested(lSorcID), .mtuRequested(rSorcID)) where lSorcID == rSorcID: return true
            case let (.connectionEstablished(lSorcID), .connectionEstablished(rSorcID))
                where lSorcID == rSorcID: return true
            case let (.connectingFailed(lError, lSorcID), .connectingFailed(rError, rSorcID))
                where lError == rError && lSorcID == rSorcID: return true
            case (.disconnect, .disconnect): return true
            case let (.connectionLost(lError), .connectionLost(rError)) where lError == rError: return true
            default: return false
            }
        }
    }
}

/// The errors that can occur if the connection attempt fails
public enum ConnectingFailedError {
    case physicalConnectingFailed
    case challengeFailed
    case blobOutdated
}

/// The errors that can occur if the connection is lost
public enum ConnectionLostError {
    case physicalConnectionLost
    case heartbeatTimedOut
}
