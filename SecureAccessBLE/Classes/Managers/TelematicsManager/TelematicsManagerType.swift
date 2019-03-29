// TelematicsManagerType.swift
// SecureAccessBLE

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

/// Defines interface for telematics manager
public protocol TelematicsManagerType {
    /// Telematics data change signal which can be used to retrieve data changes
    var telematicsDataChange: ChangeSignal<TelematicsDataChange> { get }

    /// Requests telematics data from the vehicle
    ///
    /// - Parameter types: Data types which need to be retrieved
    func requestTelematicsData(_ types: [TelematicsDataType]) -> Void
}
