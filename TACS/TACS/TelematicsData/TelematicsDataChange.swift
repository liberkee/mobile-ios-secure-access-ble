// TelematicsDataChange.swift
// SecureAccessBLE

// Created on 28.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation
import SecureAccessBLE

/// Describes the Telematics data change
public struct TelematicsDataChange: ChangeType {
    /// State which contains types of telematics data which are currently being requested
    public let state: State

    /// Action which led to change
    public let action: Action

    /// Constructor for change with initial action
    ///
    /// - Parameter state: initial state
    public static func initialWithState(_ state: State) -> TelematicsDataChange {
        return TelematicsDataChange(state: state, action: .initial)
    }

    /// State type which is an array of `TelematicsDataType`
    public typealias State = [TelematicsDataType]
}

extension TelematicsDataChange {
    /// Action which can lead to a change
    public enum Action: Equatable {
        /// Initial action
        case initial
        /// Action notifying that data is being requested with list of requested types
        case requestingData(types: [TelematicsDataType])
        /// Action notifying that responses were received with the list of responses
        case responseReceived(responses: [TelematicsDataResponse])
    }
}

extension TelematicsDataChange: Equatable {}
