// VehicleAccessManagerType.swift
// TACS

// Created on 24.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

public protocol VehicleAccessManagerType: SorcInterceptor {
    /// Vehicle access feature change which can be used to retrieve vehicle access feature changes.
    var vehicleAccessChange: ChangeSignal<VehicleAccessFeatureChange> { get }
    /// Requests a feature from vehicle.
    ///
    /// - Parameter vehicleAccessFeature: Feature which has to be requested.
    func requestFeature(_ vehicleAccessFeature: VehicleAccessFeature)
}
