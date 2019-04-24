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
                telematicsData = TelematicsData(type: .odometer,
                                                timestamp: tripMetaData.timeStamp,
                                                value: value)
            } else {
                telematicsData = nil
            }
        case .fuelLevelAbsolute:
            if let value = tripMetaData.fuelLevelAbsolute, [.both, .absoluteOnly].contains(tripMetaData.fuelLevelFlag) {
                telematicsData = TelematicsData(type: .fuelLevelAbsolute,
                                                timestamp: tripMetaData.timeStamp,
                                                value: value)
            } else {
                telematicsData = nil
            }
        case .fuelLevelPercentage:
            if let value = tripMetaData.fuelLevelPercentage, [.both, .percentageOnly].contains(tripMetaData.fuelLevelFlag) {
                telematicsData = TelematicsData(type: .fuelLevelPercentage,
                                                timestamp: tripMetaData.timeStamp,
                                                value: value)
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
