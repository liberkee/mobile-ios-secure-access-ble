// TelematicsDataError.swift
// SecureAccessBLE

// Created on 28.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

/// Possible errors which can be included in a `TelematicsDataResponse`
public enum TelematicsDataError: String {
    /// Query failed, because the vehicle is not connected
    case notConnected
    /// Query failed, because the vehicle does not provide this information
    case notSupported
    /// Query failed, because the lease does not permit access to telematics data
    case denied
    /// Query failed, because the remote CAM encountered an internal error
    case remoteFailed
}
