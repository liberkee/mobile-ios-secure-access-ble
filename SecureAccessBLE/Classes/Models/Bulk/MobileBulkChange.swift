//
//  MobileBulkChange.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 02.04.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

/// :nodoc:
public struct MobileBulkChange: ChangeType, Equatable {
    public let state: State

    public let action: Action

    public static func initialWithState(_ state: MobileBulkChange.State) -> MobileBulkChange {
        return MobileBulkChange(state: state, action: .initial)
    }

    public init(state: State, action: Action) {
        self.state = state
        self.action = action
    }
}

/// :nodoc:
public extension MobileBulkChange {
    struct State: Equatable {
        // Currently requested service grant IDs
        public let requestingBulkIDs: [UUID]

        public init(requestingBulkIDs: [UUID]) {
            self.requestingBulkIDs = requestingBulkIDs
        }
    }
}

/// :nodoc:
public extension MobileBulkChange {
    enum Action: Equatable {
        case initial

        case requestMobileBulk(bulkID: UUID, accepted: Bool)

        case responseReceived(MobileBulkResponse)

        case requestFailed(bulkID: UUID, error: MobileBulkRequestFailedError)

        case responseDataFailed(error: MobileBulkDataReceivedError)
    }

    // Error which can occur on `requestFailed` case
    enum MobileBulkRequestFailedError: Swift.Error, CustomStringConvertible {
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

    enum MobileBulkDataReceivedError: Swift.Error, CustomStringConvertible {
        case unsupportedBulkProtocolVersion

        case receivedInvalidData

        // Description of the error
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
