//
//  ServiceGrantChange.swift
//  SecureAccessBLE
//
//  Created on 08.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

/// Describes a change of service grant requesting
public struct ServiceGrantChange: ChangeType, Equatable {
    public static func initialWithState(_ state: ServiceGrantChange.State) -> ServiceGrantChange {
        return ServiceGrantChange(state: state, action: .initial)
    }

    /// The state the service grant requesting can be in
    public let state: State

    /// The action that led to the state
    public let action: Action

    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }

    public static func == (lhs: ServiceGrantChange, rhs: ServiceGrantChange) -> Bool {
        return lhs.state == rhs.state && lhs.action == rhs.action
    }
}

extension ServiceGrantChange {
    /// The state the service grant requesting can be in
    public struct State: Equatable {
        public let requestingServiceGrantIDs: [ServiceGrantID]

        public static func == (lhs: State, rhs: State) -> Bool {
            return lhs.requestingServiceGrantIDs == rhs.requestingServiceGrantIDs
        }
    }
}

extension ServiceGrantChange {
    /// The action that led to the state
    public enum Action: Equatable {
        case initial

        /// A service grant was requested, `accepted` == true, if request could be enqueued
        case requestServiceGrant(id: ServiceGrantID, accepted: Bool)
        case responseReceived(ServiceGrantResponse)
        case requestFailed(Error)
        case reset

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial):
                return true
            case let (.requestServiceGrant(lID, lAccepted), .requestServiceGrant(rID, rAccepted)):
                return lID == rID && lAccepted == rAccepted
            case let (.responseReceived(lServiceGrantResponse), .responseReceived(rServiceGrantResponse)):
                return lServiceGrantResponse == rServiceGrantResponse
            case let (.requestFailed(lError), .requestFailed(rError)):
                return lError == rError
            case (.reset, .reset):
                return true
            default:
                return false
            }
        }
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case sendingFailed
        case receivedInvalidData

        public var description: String {
            switch self {
            case .sendingFailed:
                return "Sending failed."
            case .receivedInvalidData:
                return "Invalid data was received."
            }
        }
    }
}
