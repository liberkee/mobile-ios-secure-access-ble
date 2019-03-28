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

    class TelematicsManagerDelegateMock: TelematicsManagerDelegate {
        var receivedRequestTelematicsData = 0
        var requestTelematicsDataResult: SorcManager.TelematicsRequestResult = .success
        func requestTelematicsData() -> SorcManager.TelematicsRequestResult {
            receivedRequestTelematicsData += 1
            return requestTelematicsDataResult
        }
    }

    // swiftlint:disable function_body_length line_length
    override func spec() {
        var sut: TelematicsManager!
        var consumeResult: ServiceGrantChange?
        var telematicsDataChange: TelematicsDataChange?
        var delegateMock: TelematicsManagerDelegateMock!

        beforeEach {
            sut = TelematicsManager()
            delegateMock = TelematicsManagerDelegateMock()
            sut.delegate = delegateMock
            _ = sut.telematicsDataChange.subscribe { change in
                telematicsDataChange = change
            }
        }
        describe("consume") {
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
                var change: ServiceGrantChange!
                var responseStatus: ServiceGrantResponse.Status!
                var serviceGrantID: UInt16!

                context("service grant id is telematics") {
                    beforeEach {
                        serviceGrantID = TelematicsManager.telematicsServiceGrantID
                    }
                    context("status success") {
                        responseStatus = ServiceGrantResponse.Status.success
                        beforeEach {
                            let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])

                            let response = ServiceGrantResponse(sorcID: self.sorcID,
                                                                serviceGrantID: serviceGrantID,
                                                                status: responseStatus,
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
                    context("status is invalidTimeFrame") {
                        beforeEach {
                            responseStatus = .invalidTimeFrame
                            let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                            let response = ServiceGrantResponse(sorcID: self.sorcID,
                                                                serviceGrantID: serviceGrantID,
                                                                status: responseStatus,
                                                                responseData: "")
                            let action = ServiceGrantChange.Action.responseReceived(response)
                            change = ServiceGrantChange(state: state, action: action)
                        }
                        it("notifies denied state") {
                            sut.requestTelematicsData([.odometer, .fuelLevelAbsolute, .fuelLevelPercentage])
                            _ = sut.consume(change: change)
                            var expectedResponses: [TelematicsDataResponse]?
                            if case let TelematicsDataChange.Action.responseReceived(responses) = telematicsDataChange!.action {
                                expectedResponses = responses
                            }
                            expect(expectedResponses).to(haveCount(3))
                            expect(expectedResponses).to(contain(TelematicsDataResponse.error(.odometer, .denied)))
                            expect(expectedResponses).to(contain(TelematicsDataResponse.error(.fuelLevelAbsolute, .denied)))
                            expect(expectedResponses).to(contain(TelematicsDataResponse.error(.fuelLevelPercentage, .denied)))
                        }
                    }
                }

                context("service grant id is not telematics") {
                    it("does not consume change") {
                        serviceGrantID = 4
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let response = ServiceGrantResponse(sorcID: self.sorcID,
                                                            serviceGrantID: serviceGrantID,
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

        describe("requestTelematicsData") {
            context("connected and not already requesting") {
                let requestedTypes: [TelematicsDataType] = [.odometer, .fuelLevelAbsolute]
                beforeEach {
                    sut.requestTelematicsData(requestedTypes)
                }
                it("triggers request") {
                    expect(delegateMock.receivedRequestTelematicsData) == 1
                }
                it("notifies requesting change") {
                    let expectedChange = TelematicsDataChange(state: requestedTypes,
                                                              action: .requestingData(types: requestedTypes))
                    expect(telematicsDataChange) == expectedChange
                }
            }
            context("connected and already requesting") {
                beforeEach {
                    sut.requestTelematicsData([.odometer])
                    sut.requestTelematicsData([.fuelLevelPercentage])
                }
                it("notifies updated requesting change") {
                    let state = telematicsDataChange!.state
                    var requestingTypes: [TelematicsDataType]?
                    if case let .requestingData(types)? = telematicsDataChange?.action {
                        requestingTypes = types
                    }
                    expect(state).to(haveCount(2))
                    expect(state).to(contain([.odometer, .fuelLevelPercentage]))
                    expect(requestingTypes).to(haveCount(2))
                    expect(requestingTypes).to(contain([.odometer, .fuelLevelPercentage]))
                }
                it("does not trigger request second time") {
                    expect(delegateMock.receivedRequestTelematicsData) == 1
                }
            }

            context("not connected") {
                it("notifies updated requesting change") {
                    delegateMock.requestTelematicsDataResult = .notConnected
                    let types: [TelematicsDataType] = [.odometer, .fuelLevelAbsolute]
                    sut.requestTelematicsData(types)

                    let expectedresponses = types.map { TelematicsDataResponse.error($0, .notConnected) }
                    let expectedAction = TelematicsDataChange.Action.responseReceived(responses: expectedresponses)
                    let expectedChange = TelematicsDataChange(state: [],
                                                              action: expectedAction)
                    expect(telematicsDataChange) == expectedChange
                }
            }
        }
    }

    private func tripMetaDataresponseString() -> String {
        let string = """
        {
            \"timestamp\": \"1970-01-01T00:00:00Z\",
            \"flag_fuel_level\": 3,
            \"fuel_level_percentage\": 80.88,
            \"fuel_level_absolute\": 41.56,
            \"vehicle_can_odometer\": 333000.3
        }
        """
        return string
    }
}
