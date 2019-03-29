// TelematicsData.swift
// SecureAccessBLE

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

/// Possible telematics data types which can be retrieved from the vehicle
public enum TelematicsDataType {
    /// Odometer
    case odometer
    /// Absolute fuel level
    case fuelLevelAbsolute
    /// Percentage fuel level
    case fuelLevelPercentage

    func unit() -> String {
        switch self {
        case .odometer: return "meter"
        case .fuelLevelAbsolute: return " liter"
        case .fuelLevelPercentage: return "percent"
        }
    }
}

/// Telematics data
public struct TelematicsData: Equatable {
    /// Type of the data
    public let type: TelematicsDataType
    /// Timestamp of the retrieved data
    public let timestamp: String
    /// Value of the data
    public let value: Double
    /// Unit of the data depending on type, can be meter, liter or percent
    public let unit: String

    init(type: TelematicsDataType, timestamp: String, value: Double) {
        self.type = type
        self.timestamp = timestamp
        self.value = value
        unit = type.unit()
    }
}
