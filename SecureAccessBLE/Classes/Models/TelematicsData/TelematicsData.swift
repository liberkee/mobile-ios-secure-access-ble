// TelematicsData.swift
// SecureAccessBLE

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

public enum TelematicsDataError: String {
    case notConnected // Query failed, because the vehicle is not connected
    case notSupported // Query failed, because the vehicle does not provide this information
    case denied // Query failed, because the lease does not permit access to telematics data
    case remoteFailed // Query failed, because the remote CAM encountered an internal error
}

public enum TelematicsDataResponse: Equatable {
    case success(TelematicsData)
    case error(TelematicsDataType, TelematicsDataError)

    init(tripMetaData: TripMetaData, requestedType: TelematicsDataType) {
        let telematicsData: TelematicsData?
        switch requestedType {
        case .odometer:
            if let value = tripMetaData.odometer {
                telematicsData = TelematicsData.odometer(timestamp: tripMetaData.timeStamp,
                                                         value: value,
                                                         unit: TelematicsData.odometerUnit)
            } else {
                telematicsData = nil
            }
        case .fuelLevelAbsolute:
            if let value = tripMetaData.fuelLevelAbsolute, [.both, .absoluteOnly].contains(tripMetaData.fuelLevelFlag) {
                telematicsData = TelematicsData.fuelLevelAbsolute(timestamp: tripMetaData.timeStamp,
                                                                  value: value,
                                                                  unit: TelematicsData.fuelLevelAbsoluteUnit)
            } else {
                telematicsData = nil
            }
        case .fuelLevelPercentage:
            if let value = tripMetaData.fuelLevelPercentage, [.both, .percentageOnly].contains(tripMetaData.fuelLevelFlag) {
                telematicsData = TelematicsData.fuelLevelPercentage(timestamp: tripMetaData.timeStamp,
                                                                    value: value,
                                                                    unit: TelematicsData.fuelLevelPercentageUnit)
            } else {
                telematicsData = nil
            }
        }
        if let result = telematicsData {
            self = .success(result)
        } else {
            self = .error(requestedType, .notSupported)
        }
    }
}

public enum TelematicsData: Equatable {
    static let odometerUnit = "meter"
    static let fuelLevelAbsoluteUnit = "liter"
    static let fuelLevelPercentageUnit = "percent"
    case odometer(timestamp: String, value: Double, unit: String)
    case fuelLevelAbsolute(timestamp: String, value: Double, unit: String)
    case fuelLevelPercentage(timestamp: String, value: Double, unit: String)
}
