//
//  ServiceGrantChange.swift
//  SecureAccessBLE
//
//  Created on 08.09.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

/// Describes a change of service grant requesting
public struct ServiceGrantChange: ChangeType, Equatable {
    /// The state the service grant requesting can be in
    public let state: State

    /// The action that led to the state
    public let action: Action

    /// :nodoc:
    public static func initialWithState(_ state: ServiceGrantChange.State) -> ServiceGrantChange {
        return ServiceGrantChange(state: state, action: .initial)
    }
}

extension ServiceGrantChange {
    /// The state the service grant request can be in
    public struct State: Equatable {
        /// Currently requested service grant IDs
        public let requestingServiceGrantIDs: [ServiceGrantID]
    }
}

extension ServiceGrantChange {
    /// The action that led to the state
    public enum Action: Equatable {
        /// Initial state (automatically sent on `subscribe`)
        case initial

        /// A service grant was requested, `accepted` == true, if request could be enqueued
        case requestServiceGrant(id: ServiceGrantID, accepted: Bool)

        /// Response received with `ServiceGrantResponse`
        case responseReceived(ServiceGrantResponse)

        /// Request failed with error
        case requestFailed(Error)

        /// Reset
        case reset
    }

    /// Error which can occur on `requestFailed` case
    public enum Error: Swift.Error, CustomStringConvertible {
        /// Sending service grant request failed
        case sendingFailed

        /// Received data is invalid
        case receivedInvalidData

        /// Description of the error
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
