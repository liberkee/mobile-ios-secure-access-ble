// VehicleAccessManagerType.swift
// TACS

// Created on 24.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

public protocol VehicleAccessManagerType: SorcInterceptor {
    var vehicleAccessChange: ChangeSignal<VehicleAccessFeatureChange> { get }
    func requestFeature(_ vehicleAccessFeature: VehicleAccessFeature)
}
