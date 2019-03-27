// TelematicsManagerTests.swift
// SecureAccessBLE_Tests

// Created on 26.03.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Nimble
import Quick
@testable import SecureAccessBLE
import XCTest
class TelematicsManagerTests: QuickSpec {
    private let sorcID = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!

    // swiftlint:disable function_body_length
    override func spec() {
        describe("consume") {
            var sut: TelematicsManager!
            var consumeResult: ServiceGrantChange?
            var telematicsDataChange: TelematicsDataChange?

            beforeEach {
                sut = TelematicsManager()
                _ = sut.telematicsDataChange.subscribe { change in
                    telematicsDataChange = change
                }
            }

            context("action is initial") {
                it("does not consume change") {
                    let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                    let action = ServiceGrantChange.Action.initial
                    let change = ServiceGrantChange(state: state, action: action)
                    let result = sut.consume(change: change)
                    expect(result) == change
                }
            }

            context("action is requestServiceGrant") {
                context("service grant id is telematics") {
                    beforeEach {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let action = ServiceGrantChange.Action.requestServiceGrant(id: TelematicsManager.telematicsServiceGrantID, accepted: true)
                        let change = ServiceGrantChange(state: state, action: action)
                        consumeResult = sut.consume(change: change)
                    }
                    it("consumes change") {
                        expect(consumeResult).to(beNil())
                    }
                    it("does not trigger telematicsDataChange signal") {
                        expect(telematicsDataChange) == TelematicsDataChange.initialWithState([])
                    }
                }

                context("service grant id is not telematics") {
                    it("does not consume change") {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let action = ServiceGrantChange.Action.requestServiceGrant(id: 5, accepted: true)
                        let change = ServiceGrantChange(state: state, action: action)
                        let result = sut.consume(change: change)
                        expect(result) == change
                    }
                }
            }

            context("action is responseReceived") {
                context("service grant id is telematics") {
                    var change: ServiceGrantChange!
                    beforeEach {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let response = ServiceGrantResponse(sorcID: self.sorcID,
                                                            serviceGrantID: TelematicsManager.telematicsServiceGrantID,
                                                            status: ServiceGrantResponse.Status.success,
                                                            responseData: self.tripMetaDataresponseString())
                        let action = ServiceGrantChange.Action.responseReceived(response)
                        change = ServiceGrantChange(state: state, action: action)
                    }

                    it("consumes change") {
                        expect(consumeResult).to(beNil())
                    }
                    context("all data was requested") {
                        beforeEach {
                            sut.requestTelematicsData([.odometer, .fuelLevelAbsolute, .fuelLevelPercentage])
                        }
                        context("response is success containing requested data") {
                            var expectedResponses: [TelematicsDataResponse]?
                            beforeEach {
                                consumeResult = sut.consume(change: change)
                                if case let TelematicsDataChange.Action.responseReceived(responses) = telematicsDataChange!.action {
                                    expectedResponses = responses
                                }
                            }
                            it("notifies telematics change") {
                                expect(expectedResponses).to(haveCount(3))
                            }
                            it("notified change contains odometer data") {
                                let expectedOdometerData = TelematicsData.odometer(timestamp: "1970-01-01T00:00:00Z",
                                                                                   value: 333_000.3,
                                                                                   unit: TelematicsData.odometerUnit)
                                expect(expectedResponses).to(contain(TelematicsDataResponse.success(expectedOdometerData)))
                            }
                            it("notified change contains fuel absolute data") {
                                let expectedFuelLevelAbsoluteData = TelematicsData.fuelLevelAbsolute(timestamp: "1970-01-01T00:00:00Z",
                                                                                                     value: 41.56,
                                                                                                     unit: TelematicsData.fuelLevelAbsoluteUnit)
                                expect(expectedResponses).to(contain(TelematicsDataResponse.success(expectedFuelLevelAbsoluteData)))
                            }
                            it("notified change contains fuel percentage data") {
                                let expectedFuelLevelRelativeData = TelematicsData.fuelLevelPercentage(timestamp: "1970-01-01T00:00:00Z",
                                                                                                       value: 80.88,
                                                                                                       unit: TelematicsData.fuelLevelPercentageUnit)
                                expect(expectedResponses).to(contain(TelematicsDataResponse.success(expectedFuelLevelRelativeData)))
                            }
                        }
                    }
                }

                context("service grant id is not telematics") {
                    it("does not consume change") {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let response = ServiceGrantResponse(sorcID: self.sorcID,
                                                            serviceGrantID: 4,
                                                            status: ServiceGrantResponse.Status.success,
                                                            responseData: "FOO")
                        let action = ServiceGrantChange.Action.responseReceived(response)
                        let change = ServiceGrantChange(state: state, action: action)
                        let result = sut.consume(change: change)
                        expect(result) == change
                    }
                }
            }

            context("action is requestFailed") {
                it("does not consume change") {
                    let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                    let action = ServiceGrantChange.Action.requestFailed(.sendingFailed)
                    let change = ServiceGrantChange(state: state, action: action)
                    let result = sut.consume(change: change)
                    expect(result) == change
                }
            }

            context("action is reset") {
                it("does not consume change") {
                    let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                    let action = ServiceGrantChange.Action.reset
                    let change = ServiceGrantChange(state: state, action: action)
                    let result = sut.consume(change: change)
                    expect(result) == change
                }
            }

            context("state contains telematics id") {
                it("telematics id is removed") {
                    let state = ServiceGrantChange.State(requestingServiceGrantIDs: [9])
                    let change = ServiceGrantChange.initialWithState(state)
                    let result = sut.consume(change: change)
                    let expectedChange = ServiceGrantChange(state: .init(requestingServiceGrantIDs: []), action: .initial)
                    expect(result) == expectedChange
                }
            }
        }
    }

    private func tripMetaDataresponseString() -> String {
        let string = """
        {
            \"timestamp\": \"1970-01-01T00:00:00Z\",
            \"flag_fuel_level\": 1,
            \"fuel_level_percentage\": 80.88,
            \"fuel_level_absolute\": 41.56,
            \"vehicle_can_odometer\": 333000.3
        }
        """
        return string
    }
}
