// TelematicsManagerInternalType.swift
// SecureAccessBLE

// Created on 28.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

// Protocol which describes internal telematics manager interface which is not exposed to the customer
protocol TelematicsManagerInternalType {
    var delegate: TelematicsManagerDelegate? { get set }
    func consume(change: ServiceGrantChange) -> ServiceGrantChange?
}
