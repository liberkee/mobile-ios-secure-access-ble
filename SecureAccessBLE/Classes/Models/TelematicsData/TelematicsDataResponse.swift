// TelematicsDataResponse.swift
// SecureAccessBLE

// Created on 28.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

/// Telematics data response which can be delivered via `TelematicsDataChange`
public enum TelematicsDataResponse: Equatable {
    /// Success case with associated telematics data
    case success(TelematicsData)
    /// Error case with associated requested data type and error
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
