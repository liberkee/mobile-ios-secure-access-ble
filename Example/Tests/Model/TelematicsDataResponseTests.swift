// TelematicsDataTests.swift
// SecureAccessBLE_Tests

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Nimble
import Quick
@testable import SecureAccessBLE

class TelematicsDataResponseTests: QuickSpec {
    override func spec() {
        describe("init") {
            context("requested type odometer") {
                context("response contains data") {
                    it("success with data") {
                        let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                        fuelLevelFlag: .absoluteOnly,
                                                        fuelLevelPercentage: 80.00,
                                                        fuelLevelAbsolute: 80.00,
                                                        odometer: 160_000.9)

                        let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .odometer)
                        let expectedData = TelematicsData.odometer(timestamp: "1970-01-01T00:00:00Z",
                                                                   value: 160_000.9,
                                                                   unit: TelematicsData.odometerUnit)
                        let expectedResponse = TelematicsDataResponse.success(expectedData)
                        expect(sut) == expectedResponse
                    }
                }

                context("response does not contain data") {
                    it("not supported") {
                        let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                        fuelLevelFlag: .absoluteOnly,
                                                        fuelLevelPercentage: 80.00,
                                                        fuelLevelAbsolute: 80.00,
                                                        odometer: nil)

                        let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .odometer)
                        let expectedResponse = TelematicsDataResponse.error(.odometer, .notSupported)
                        expect(sut) == expectedResponse
                    }
                }
            }
            context("requested type fuelLevelAbsolute") {
                context("response contains data") {
                    it("success with data") {
                        let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                        fuelLevelFlag: .absoluteOnly,
                                                        fuelLevelPercentage: nil,
                                                        fuelLevelAbsolute: 80.00,
                                                        odometer: nil)

                        let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelAbsolute)
                        let expectedData = TelematicsData.fuelLevelAbsolute(timestamp: "1970-01-01T00:00:00Z",
                                                                            value: 80.0,
                                                                            unit: TelematicsData.fuelLevelAbsoluteUnit)
                        let expectedResponse = TelematicsDataResponse.success(expectedData)
                        expect(sut) == expectedResponse
                    }
                }

                context("response does not contain data") {
                    it("not supported") {
                        let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                        fuelLevelFlag: .absoluteOnly,
                                                        fuelLevelPercentage: nil,
                                                        fuelLevelAbsolute: nil,
                                                        odometer: nil)

                        let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelAbsolute)
                        let expectedResponse = TelematicsDataResponse.error(.fuelLevelAbsolute, .notSupported)
                        expect(sut) == expectedResponse
                    }
                }
            }
            context("requested type fuelLevelPercentage") {
                context("response contains data") {
                    it("success with data") {
                        let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                        fuelLevelFlag: .absoluteOnly,
                                                        fuelLevelPercentage: 90.0,
                                                        fuelLevelAbsolute: nil,
                                                        odometer: nil)

                        let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelPercentage)
                        let expectedData = TelematicsData.fuelLevelPercentage(timestamp: "1970-01-01T00:00:00Z",
                                                                              value: 90.0,
                                                                              unit: TelematicsData.fuelLevelPercentageUnit)
                        let expectedResponse = TelematicsDataResponse.success(expectedData)
                        expect(sut) == expectedResponse
                    }
                }

                context("response does not contain data") {
                    it("not supported") {
                        let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                        fuelLevelFlag: .absoluteOnly,
                                                        fuelLevelPercentage: nil,
                                                        fuelLevelAbsolute: nil,
                                                        odometer: nil)

                        let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelPercentage)
                        let expectedResponse = TelematicsDataResponse.error(.fuelLevelPercentage, .notSupported)
                        expect(sut) == expectedResponse
                    }
                }
            }
        }
    }
}
