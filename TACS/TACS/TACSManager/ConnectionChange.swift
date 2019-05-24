// ConnectionChange.swift
// TACS

// Created on 02.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

// The ConnectionChange is an extended version of its SecureAccessBLE counterpart.
// We perform a mapping of SecureAccessBLE.ConectionChange here.

struct SorcIDToVehicleRefMapMismatch: Error {}

/// Describes a change of connection state
public struct ConnectionChange: ChangeType, Equatable {
    /// The state the connection can be in
    public let state: State

    /// The action that led to the state
    public let action: Action

    /// :nodoc:
    public static func initialWithState(_ state: State) -> ConnectionChange {
        return ConnectionChange(state: state, action: .initial)
    }

    /// :nodoc:
    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }

    internal init(from change: SecureAccessBLE.ConnectionChange, activeSorcID: SorcID, activeVehicleRef: VehicleRef) throws {
        state = try State(from: change.state, activeSorcID: activeSorcID, activeVehicleRef: activeVehicleRef)
        action = try Action(from: change.action, activeSorcID: activeSorcID, activeVehicleRef: activeVehicleRef)
    }
}

extension ConnectionChange {
    /// The state the connection can be in
    public enum State: Equatable {
        /// Disconnected
        case disconnected

        /// Connecting to a specific `VehicleRef` in the current `ConnectingState`
        case connecting(vehicleRef: VehicleRef, state: ConnectingState)

        /// Connected to a specific `VehicleRef`
        case connected(vehicleRef: VehicleRef)

        /// The state when connecting to a SORC
        public enum ConnectingState {
            /// Physical state
            case physical

            /// Transport state
            case transport

            /// Challenging state
            case challenging

            init(from state: SecureAccessBLE.ConnectionChange.State.ConnectingState) {
                switch state {
                case .physical: self = .physical
                case .transport: self = .transport
                case .challenging: self = .challenging
                }
            }
        }

        init(from state: SecureAccessBLE.ConnectionChange.State, activeSorcID: SorcID, activeVehicleRef: VehicleRef) throws {
            switch state {
            case .disconnected:
                self = .disconnected
            case let .connecting(sorcID: sorcId, state: state):
                guard sorcId == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .connecting(vehicleRef: activeVehicleRef, state: ConnectingState(from: state))
            case let .connected(sorcID: sorcId):
                guard sorcId == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .connected(vehicleRef: activeVehicleRef)
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
        case connect(vehicleRef: VehicleRef)

        /// Physical connection with provided `VehicleRef` established
        case physicalConnectionEstablished(vehicleRef: VehicleRef)

        /// Transport connection with provided `VehicleRef` established
        case transportConnectionEstablished(vehicleRef: VehicleRef)

        /// Connection with provided `VehicleRef` established
        case connectionEstablished(vehicleRef: VehicleRef)

        /// Connecting to provided `VehicleRef` failed with `ConnectingFailedError`
        case connectingFailed(vehicleRef: VehicleRef, error: ConnectingFailedError)

        /// Connecting failed due to missing blob data.
        case connectingFailedDataMissing

        /// Disconnect
        case disconnect

        /// Connection lost with `ConnectionLostError`
        case connectionLost(error: ConnectionLostError)

        // swiftlint:disable:next cyclomatic_complexity
        init(from action: SecureAccessBLE.ConnectionChange.Action, activeSorcID: SorcID, activeVehicleRef: VehicleRef) throws {
            switch action {
            case .initial:
                self = .initial
            case let .connect(sorcID):
                guard sorcID == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .connect(vehicleRef: activeVehicleRef)
            case let .physicalConnectionEstablished(sorcID):
                guard sorcID == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .physicalConnectionEstablished(vehicleRef: activeVehicleRef)
            case let .transportConnectionEstablished(sorcID):
                guard sorcID == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .transportConnectionEstablished(vehicleRef: activeVehicleRef)
            case let .connectionEstablished(sorcID):
                guard sorcID == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .connectionEstablished(vehicleRef: activeVehicleRef)
            case let .connectingFailed(sorcID, error):
                guard sorcID == activeSorcID else { throw SorcIDToVehicleRefMapMismatch() }
                self = .connectingFailed(vehicleRef: activeVehicleRef, error: ConnectingFailedError(from: error))
            case .disconnect:
                self = .disconnect
            case let .connectionLost(error):
                self = .connectionLost(error: ConnectionLostError(from: error))
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

    /// BLOB time check failed
    case invalidTimeFrame

    init(from error: SecureAccessBLE.ConnectingFailedError) {
        switch error {
        case .physicalConnectingFailed: self = .physicalConnectingFailed
        case .invalidMTUResponse: self = .invalidMTUResponse
        case .challengeFailed: self = .challengeFailed
        case .blobOutdated: self = .blobOutdated
        case .invalidTimeFrame: self = .invalidTimeFrame
        }
    }
}

/// The errors that can occur if the connection is lost
public enum ConnectionLostError: Error {
    /// Physical connection is lost
    case physicalConnectionLost

    /// Heartbeat has timed out
    case heartbeatTimedOut

    init(from error: SecureAccessBLE.ConnectionLostError) {
        switch error {
        case .heartbeatTimedOut: self = .heartbeatTimedOut
        case .physicalConnectionLost: self = .physicalConnectionLost
        }
    }
}
