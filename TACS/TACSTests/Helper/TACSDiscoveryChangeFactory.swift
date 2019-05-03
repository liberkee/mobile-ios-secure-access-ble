// TACSDiscoveryChangeFactory.swift
// TACSTests

// Created on 03.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
@testable import TACS

class TACSDiscoveryChangeFactory {
    static func discoveredChange(with vehicleRef: VehicleRef, date: Date = Date()) -> DiscoveryChange {
        let vehicleInfo = VehicleInfo(vehicleRef: vehicleRef, discoveryDate: date, rssi: 1)
        let vehicleInfos = VehicleInfos([vehicleRef: vehicleInfo])
        let state = DiscoveryChange.State(discoveredVehicles: vehicleInfos)
        let action = DiscoveryChange.Action.discovered(vehicleRef: vehicleRef)
        let change = DiscoveryChange(state: state, action: action)
        return change
    }
}
