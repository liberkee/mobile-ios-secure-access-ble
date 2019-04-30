// TACSManagerIntegrationTests.swift
// TACSTests

// Created on 26.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick
import SecureAccessBLE
@testable import TACS

class TACSManagerIntegrationTests: QuickSpec {
    class SorcManagerMock: SorcManagerDefaultMock {
        let sorcID = UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
        func setConnected(_ connected: Bool) {
            if connected {
                connectionChangeSubject.onNext(ConnectionChange(state: .connected(sorcID: sorcID),
                                                                action: .connectionEstablished(sorcID: sorcID)))
            } else {
                connectionChangeSubject.onNext(ConnectionChange(state: .disconnected, action: .disconnect))
            }
        }
    }

    // swiftlint:disable:next function_body_length
    override func spec() {
        var sorcManagerMock: SorcManagerMock!
        var sut: TACSManager!
        var telematicsDataChanges: [TelematicsDataChange]!
        var vehicleAccessChanges: [VehicleAccessFeatureChange]!
        beforeEach {
            sorcManagerMock = SorcManagerMock()
            let telematicsManager = TelematicsManager(sorcManager: sorcManagerMock)
            let vehicleAccessManager = VehicleAccessManager(sorcManager: sorcManagerMock)
            sut = TACSManager(sorcManager: sorcManagerMock,
                              telematicsManager: telematicsManager,
                              vehicleAccessManager: vehicleAccessManager)
            telematicsDataChanges = []
            vehicleAccessChanges = []
            _ = sut.telematicsManager.telematicsDataChange.subscribe { change in
                telematicsDataChanges.append(change)
            }
            _ = sut.vehicleAccessManager.vehicleAccessChange.subscribe { change in
                vehicleAccessChanges.append(change)
            }
        }
        describe("init") {
            it("interceptors registered") {
                expect(sorcManagerMock.didReceiveRegisterInterceptor) == 2
                expect(sorcManagerMock.receivedRegisterInterceptorInterceptors[0]) === sut.telematicsManager
                expect(sorcManagerMock.receivedRegisterInterceptorInterceptors[1]) === sut.vehicleAccessManager
            }
        }

        describe("send requests via both managers in connected state") {
            beforeEach {
                sorcManagerMock.setConnected(true)
                sut.telematicsManager.requestTelematicsData([.odometer])
                sut.vehicleAccessManager.requestFeature(.lock)
            }
            context("no change from sorcManager received") {
                it("no change notified via managers") {
                    expect(telematicsDataChanges) == [TelematicsDataChange.initialWithState([])]
                    expect(vehicleAccessChanges) == [VehicleAccessFeatureChange.initialWithState([])]
                }
            }
            context("request change with telematics id notified") {
                beforeEach {
                    _ = sut.telematicsManager.consume(change: ServiceGrantChangeFactory.acceptedTelematicsRequestChange())
                }
                it("telematics manager notifies change") {
                    expect(telematicsDataChanges).to(haveCount(2))
                    expect(telematicsDataChanges[1]) == TelematicsDataChange(state: [.odometer],
                                                                             action: .requestingData(types: [.odometer]))
                }
                it("vehicle access manager does not notify change") {
                    expect(vehicleAccessChanges) == [VehicleAccessFeatureChange.initialWithState([])]
                }
            }

            context("request change with feature") {
                beforeEach {
                    _ = sut.vehicleAccessManager.consume(change: ServiceGrantChangeFactory.acceptedRequestChange(feature: .lock))
                }
                it("telematics manager does not notify change") {
                    expect(telematicsDataChanges) == [TelematicsDataChange.initialWithState([])]
                }
                it("vehicle access manager does not notify change") {
                    expect(vehicleAccessChanges).to(haveCount(2))
                    let expectedChange = VehicleAccessFeatureChange(state: [.lock],
                                                                    action: .requestFeature(feature: .lock, accepted: true))
                    expect(vehicleAccessChanges[1]) == expectedChange
                }
            }
        }
    }
}
