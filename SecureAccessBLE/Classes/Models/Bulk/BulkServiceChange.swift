//
//  BulkServiceChange.swift
//  SecureAccessBLE
//
//  Created by Priya Khatri on 02.04.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

/// Describes a change of mobile bulk service requesting
public struct BulkServiceChange: ChangeType, Equatable {
    /// State which represents if a bulk service request is pending or not
    public let state: State

    public let action: Action

    public typealias State = Bool

    public static func initialWithState(_: Bool) -> BulkServiceChange {
        return BulkServiceChange(state: false, action: .initial)
    }

    /// :nodoc:
    public init(state: Bool, action: Action) {
        self.state = state
        self.action = action
    }
}

extension BulkServiceChange {
    public enum Action: Equatable {
        case initial

        case requestBulk

        case responseReceived(BulkResponseMessage)

        case requestFailed
    }
}
