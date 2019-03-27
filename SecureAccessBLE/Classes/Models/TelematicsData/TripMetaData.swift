// TripMetaData.swift
// SecureAccessBLE_Tests

// Created on 27.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

struct TripMetaData: Decodable {
    enum FuelLevelFlag: Int, Decodable {
        case unavailable = 0, percentageOnly = 1, absoluteOnly = 2, both = 3
    }

    let timeStamp: String
    let fuelLevelFlag: FuelLevelFlag
    let fuelLevelPercentage: Double?
    let fuelLevelAbsolute: Double?
    let odometer: Double?

    enum CodingKeys: String, CodingKey {
        case timeStamp = "timestamp"
        case fuelLevelFlag = "flag_fuel_level"
        case fuelLevelPercentage = "fuel_level_percentage"
        case fuelLevelAbsolute = "fuel_level_absolute"
        case odometer = "vehicle_can_odometer"
    }

    enum Error: Swift.Error {
        case parseError
    }

    init(responseData: String) throws {
        guard let data = responseData.data(using: .utf8) else {
            throw Error.parseError
        }
        do {
            self = try JSONDecoder().decode(TripMetaData.self, from: data)
        } catch {
            throw Error.parseError
        }
    }
}

extension TripMetaData: Equatable {}

extension TripMetaData {
    init(timeStamp: String,
         fuelLevelFlag: FuelLevelFlag,
         fuelLevelPercentage: Double?,
         fuelLevelAbsolute: Double?,
         odometer: Double?) {
        self.timeStamp = timeStamp
        self.fuelLevelFlag = fuelLevelFlag
        self.fuelLevelPercentage = fuelLevelPercentage
        self.fuelLevelAbsolute = fuelLevelAbsolute
        self.odometer = odometer
    }
}
