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
}

/// Telematics data
public enum TelematicsData: Equatable {
    static let odometerUnit = "meter"
    static let fuelLevelAbsoluteUnit = "liter"
    static let fuelLevelPercentageUnit = "percent"
    /// Odometer data
    case odometer(timestamp: String, value: Double, unit: String)
    /// Absolute fuel level data
    case fuelLevelAbsolute(timestamp: String, value: Double, unit: String)
    /// Percentage fuel level data
    case fuelLevelPercentage(timestamp: String, value: Double, unit: String)
}
