// VehicleAccessFeatureChange.swift
// TACS

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

public struct VehicleAccessFeatureChange: ChangeType {
    public var state: State
    public var action: Action

    public static func initialWithState(_ state: [VehicleAccessFeature]) -> VehicleAccessFeatureChange {
        return VehicleAccessFeatureChange(state: state, action: .initial)
    }

    public typealias State = [VehicleAccessFeature]
}

extension VehicleAccessFeatureChange {
    public enum Action: Equatable {
        case initial
        case requestFeature(feature: VehicleAccessFeature, accepted: Bool)
        case responseReceived(response: VehicleAccessFeatureResponse)
    }
}

extension VehicleAccessFeatureChange: Equatable {}
