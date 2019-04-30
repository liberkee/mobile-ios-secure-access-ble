// TACSManagerTests.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick
@testable import TACS

class TACSManagerTests: QuickSpec {
    override func spec() {
        describe("init") {
            it("should not be nil") {
                let sorcManager = SorcManagerDefaultMock()
                let telematicsManager = TelematicsManagerDefaultMock()
                let vehicleAccessManager = VehicleAccessManagerDefaultMock()
                let sut = TACSManager(sorcManager: sorcManager,
                                      telematicsManager: telematicsManager,
                                      vehicleAccessManager: vehicleAccessManager)

                expect(sut).toNot(beNil())
            }
        }
    }
}
