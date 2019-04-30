// TelematicsDataTests.swift
// SecureAccessBLE_Tests

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Nimble
import Quick
@testable import SecureAccessBLE
@testable import TACS

class TelematicsDataResponseTests: QuickSpec {
    // swiftlint:disable:next function_body_length
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
                        let expectedData = TelematicsData(type: .odometer,
                                                          timestamp: "1970-01-01T00:00:00Z",
                                                          value: 160_000.9)
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
                    context("flag is absoluteOnly or both") {
                        it("success with data") {
                            for flag: TripMetaData.FuelLevelFlag in [.both, .absoluteOnly] {
                                let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                                fuelLevelFlag: flag,
                                                                fuelLevelPercentage: nil,
                                                                fuelLevelAbsolute: 80.00,
                                                                odometer: nil)

                                let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelAbsolute)
                                let expectedData = TelematicsData(type: .fuelLevelAbsolute,
                                                                  timestamp: "1970-01-01T00:00:00Z",
                                                                  value: 80.0)
                                let expectedResponse = TelematicsDataResponse.success(expectedData)
                                expect(sut) == expectedResponse
                            }
                        }
                    }
                    context("flag is unavailable or percentageOnly") {
                        it("not supported") {
                            for flag: TripMetaData.FuelLevelFlag in [.unavailable, .percentageOnly] {
                                let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                                fuelLevelFlag: flag,
                                                                fuelLevelPercentage: nil,
                                                                fuelLevelAbsolute: 80.00,
                                                                odometer: nil)

                                let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelAbsolute)

                                let expectedResponse = TelematicsDataResponse.error(.fuelLevelAbsolute, .notSupported)
                                expect(sut) == expectedResponse
                            }
                        }
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
                    context("flag is percentageOnly or both") {
                        it("success with data") {
                            for flag: TripMetaData.FuelLevelFlag in [.both, .percentageOnly] {
                                let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                                fuelLevelFlag: flag,
                                                                fuelLevelPercentage: 90.0,
                                                                fuelLevelAbsolute: nil,
                                                                odometer: nil)

                                let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelPercentage)
                                let expectedData = TelematicsData(type: .fuelLevelPercentage,
                                                                  timestamp: "1970-01-01T00:00:00Z",
                                                                  value: 90.0)
                                let expectedResponse = TelematicsDataResponse.success(expectedData)
                                expect(sut) == expectedResponse
                            }
                        }
                    }
                    context("flag is percentageOnly or both") {
                        it("not supported") {
                            for flag: TripMetaData.FuelLevelFlag in [.unavailable, .absoluteOnly] {
                                let tripMetaData = TripMetaData(timeStamp: "1970-01-01T00:00:00Z",
                                                                fuelLevelFlag: flag,
                                                                fuelLevelPercentage: 90.0,
                                                                fuelLevelAbsolute: nil,
                                                                odometer: nil)

                                let sut = TelematicsDataResponse(tripMetaData: tripMetaData, requestedType: .fuelLevelPercentage)
                                let expectedResponse = TelematicsDataResponse.error(.fuelLevelPercentage, .notSupported)
                                expect(sut) == expectedResponse
                            }
                        }
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
