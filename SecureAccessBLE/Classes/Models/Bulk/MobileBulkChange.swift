//
//  MobileBulkChange.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 02.04.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

/// Describes a change of mobile bulk requesting
public struct MobileBulkChange: ChangeType, Equatable {
    public let state: State

    public let action: Action

    public static func initialWithState(_ state: MobileBulkChange.State) -> MobileBulkChange {
        return MobileBulkChange(state: state, action: .initial)
    }

    /// :nodoc:
    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

extension MobileBulkChange {
    /// The state the service grant request can be in
    public struct State: Equatable {
        /// Currently requested service grant IDs
        public let requestingBulkIDs: [UUID]

        /// :nodoc:
        public init(requestingBulkIDs: [UUID]) {
            self.requestingBulkIDs = requestingBulkIDs
        }
    }
}

extension MobileBulkChange {
    public enum Action: Equatable {
        case initial

        case requestMobileBulk(bulkID: UUID, accepted: Bool)

        case responseReceived(MobileBulkResponse)

        case requestFailed(bulkID: UUID, error: MobileBulkRequestFailedError)

        case responseDataFailed(error: MobileBulkDataReceivedError)
    }

    /// Error which can occur on `requestFailed` case
    public enum MobileBulkRequestFailedError: Swift.Error, CustomStringConvertible {
        case notConnected

        case invalidBulkFormat

        /// Description of the error
        public var description: String {
            switch self {
            case .invalidBulkFormat:
                return "Invalid data format."
            case .notConnected:
                return "Not connected to the SORC"
            }
        }
    }

    public enum MobileBulkDataReceivedError: Swift.Error, CustomStringConvertible {
        case unsupportedBulkProtocolVersion

        case receivedInvalidData

        /// Description of the error
        public var description: String {
            switch self {
            case .receivedInvalidData:
                return "Invalid data was received."
            case .unsupportedBulkProtocolVersion:
                return "Invalid Bulk protocol version was received"
            }
        }
    }
}
