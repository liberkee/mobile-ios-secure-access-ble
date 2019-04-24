// VehileAccessManager.swift
// TACS

// Created on 23.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import SecureAccessBLE

class VehicleAccessManager: VehicleAccessManagerType {
    private let sorcManager: SorcManagerType
    
    init(sorcManager: SorcManagerType) {
        self.sorcManager = sorcManager
    }
}

extension VehicleAccessManager: SorcInterceptor {
    func consume(change: ServiceGrantChange) -> ServiceGrantChange? {
        return change
    }
}
