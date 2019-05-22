// KeyholderStatusChange.swift
// TACS

// Created on 21.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

public struct KeyholderStatusChange: ChangeType, Equatable {
    public static func initialWithState(_ state: KeyholderStatusChange.State) -> KeyholderStatusChange {
        return KeyholderStatusChange(state: state, action: .initial)
    }

    public let state: State

    public let action: Action
}

extension KeyholderStatusChange {
    public enum Action: Equatable {
        /// Initial action
        case initial
        /// Action notifying that discovery has started
        case discoveryStarted
        /// Action notifying that keyholder was discovered with associated keyholder info
        case discovered(KeyholderInfo)
        /// Action notifying that an error occured
        case failed(KeyholderStatusError)
    }

    public enum State: Equatable {
        case searching
        case stopped
    }
}

/// Error in retrieving keyholder status
public enum KeyholderStatusError: Equatable {
    /// Bluetooth interface is powered off
    case bluetoothOff
    /// Keyholder id is missing. This can occure if the keyring was not set on `TacsManager` or
    /// if the selected key does not contain a keyholder id which is e.g. the case for passive start vehicles
    case keyholderIdMissing
    /// Keyholder could not be discovered due to time out
    case scanTimeout
}
