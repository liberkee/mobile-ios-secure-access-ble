// VehicleAccessManagerTests.swift
// TACSTests

// Created on 26.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick
@testable import SecureAccessBLE
@testable import TACS

class VehicleAccessManagerTests: QuickSpec {
    static let sorcID = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!

    // swiftlint:disable:next function_body_length
    override func spec() {
        var sut: VehicleAccessManager!
        var sorcManagerMock: SorcManagerDefaultMock!
        var vehicleAccessChange: VehicleAccessFeatureChange!
        beforeEach {
            sorcManagerMock = SorcManagerDefaultMock()
            sut = VehicleAccessManager(sorcManager: sorcManagerMock)
            _ = sut.vehicleAccessChange.subscribe { change in
                vehicleAccessChange = change
            }
        }
        describe("init") {
            it("should not be nil") {
                let sut = VehicleAccessManager(sorcManager: SorcManagerDefaultMock())
                expect(sut).toNot(beNil())
            }
        }

        // MARK: - consume

        describe("consume") {
            // MARK: initial

            context("initial") {
                it("consumes change") {
                    let change = ServiceGrantChange.initialWithState(.init(requestingServiceGrantIDs: []))
                    let changeAfterConsume = sut.consume(change: change)
                    expect(changeAfterConsume).to(beNil())
                }
            }

            // MARK: requestServiceGrant

            context("requestServiceGrant") {
                context("grantIDNotKnown") {
                    it("does not consume") {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let action = ServiceGrantChange.Action.requestServiceGrant(id: TelematicsManager.telematicsServiceGrantID, accepted: true)
                        let change = ServiceGrantChange(state: state,
                                                        action: action)
                        let changeAfterConsume = sut.consume(change: change)
                        expect(changeAfterConsume) == change
                    }
                    it("removes requested features from state") {
                        let requestingSGIDs: [ServiceGrantID] = [
                            VehicleAccessFeature.lock.serviceGrantID(),
                            VehicleAccessFeature.unlock.serviceGrantID(),
                            TelematicsManager.telematicsServiceGrantID
                        ]
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: requestingSGIDs)
                        let action = ServiceGrantChange.Action.requestServiceGrant(id: TelematicsManager.telematicsServiceGrantID, accepted: true)
                        let change = ServiceGrantChange(state: state,
                                                        action: action)

                        // request features and ack them via .requestServiceGrant change
                        sut.requestFeature(.lock)
                        sut.requestFeature(.unlock)
                        _ = sut.consume(change: ServiceGrantChangeFactory.acceptedRequestChange(feature: .lock))
                        _ = sut.consume(change: ServiceGrantChangeFactory.acceptedRequestChange(feature: .unlock))

                        // now the change, although not consumed, does not contain service grants which SUT is waiting for
                        let changeAfterConsume = sut.consume(change: change)
                        expect(changeAfterConsume!.state.requestingServiceGrantIDs) == [TelematicsManager.telematicsServiceGrantID]
                    }
                }
                context("grantIDKnown") {
                    var serviceGrantChange: ServiceGrantChange!
                    let feature = VehicleAccessFeature.lock
                    beforeEach {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let action = ServiceGrantChange.Action.requestServiceGrant(id: feature.serviceGrantID(), accepted: true)
                        serviceGrantChange = ServiceGrantChange(state: state, action: action)
                    }
                    context("feature was requested") {
                        beforeEach {
                            sut.requestFeature(feature)
                        }
                        it("consumes change") {
                            let changeAfterConsume = sut.consume(change: serviceGrantChange)
                            expect(changeAfterConsume).to(beNil())
                        }
                        it("notifies feature change") {
                            let expectedState = [feature]
                            let expectedAction = VehicleAccessFeatureChange.Action.requestFeature(feature: feature, accepted: true)
                            let expectedChange = VehicleAccessFeatureChange(state: expectedState, action: expectedAction)
                            _ = sut.consume(change: serviceGrantChange)
                            expect(vehicleAccessChange) == expectedChange
                        }
                    }
                    context("feature was not requested") {
                        it("does not consume change") {
                            let changeAfterConsume = sut.consume(change: serviceGrantChange)
                            expect(changeAfterConsume) == serviceGrantChange
                        }
                    }
                }
            }

            // MARK: responseReceived

            context("responseReceived") {
                context("grantIDNotKnown") {
                    it("does not consume") {
                        let state = ServiceGrantChange.State(requestingServiceGrantIDs: [])
                        let response = ServiceGrantResponse(sorcID: VehicleAccessManagerTests.sorcID,
                                                            serviceGrantID: TelematicsManager.telematicsServiceGrantID,
                                                            status: ServiceGrantResponse.Status.success,
                                                            responseData: "")
                        let action = ServiceGrantChange.Action.responseReceived(response)
                        let change = ServiceGrantChange(state: state,
                                                        action: action)
                        let changeAfterConsume = sut.consume(change: change)
                        expect(changeAfterConsume) == change
                    }
                }
                context("grantIDKnown") {
                    var serviceGrantChange: ServiceGrantChange!
                    var feature: VehicleAccessFeature!
                    beforeEach {
                        feature = .lock
                        serviceGrantChange = ServiceGrantChangeFactory.responseReceivedChange(feature: feature)
                    }
                    context("feature was requested and acked") {
                        beforeEach {
                            sut.requestFeature(feature)
                            _ = sut.consume(change: ServiceGrantChangeFactory.acceptedRequestChange(feature: .lock))
                        }
                        it("consumes change") {
                            let changeAfterConsume = sut.consume(change: serviceGrantChange)
                            expect(changeAfterConsume).to(beNil())
                        }
                        it("notifies feature change") {
                            let expectedState: [VehicleAccessFeature] = [] // no waiting features in the queue anymore
                            let expectedResponse = VehicleAccessFeatureResponse.success(status: VehicleAccessFeatureStatus.lock)
                            let expectedAction = VehicleAccessFeatureChange.Action.responseReceived(response: expectedResponse)
                            let expectedChange = VehicleAccessFeatureChange(state: expectedState, action: expectedAction)
                            _ = sut.consume(change: serviceGrantChange)
                            expect(vehicleAccessChange) == expectedChange
                        }
                    }
                    context("feature was not requested") {
                        it("does not consume change") {
                            let changeAfterConsume = sut.consume(change: serviceGrantChange)
                            expect(changeAfterConsume) == serviceGrantChange
                        }
                    }
                }
            }
        }
    }
}
