// VehicleAccessManagerDefaultMock.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.


@testable import TACS
import SecureAccessBLE

class VehicleAccessManagerDefaultMock: VehicleAccessManagerType {
    var changeAfterConsume: ServiceGrantChange?
    func consume(change: ServiceGrantChange) -> ServiceGrantChange? {
        return changeAfterConsume
    }
    func requestFeature(_ vehicleAccessFeature: VehicleAccessFeature) {}
}
