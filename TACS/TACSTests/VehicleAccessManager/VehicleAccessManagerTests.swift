// VehicleAccessManagerTests.swift
// TACSTests

// Created on 26.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.


import Quick
import Nimble
@testable import TACS
@testable import SecureAccessBLE

class VehicleAccessManagerTests: QuickSpec {
    override func spec() {
        var sut: VehicleAccessManager!
        var sorcManagerMock: SorcManagerDefaultMock!
        
        beforeEach {
            sorcManagerMock = SorcManagerDefaultMock()
            sut = VehicleAccessManager(sorcManager: sorcManagerMock)
        }
        describe("init") {
            it("should not be nil") {
                let sut = VehicleAccessManager(sorcManager: SorcManagerDefaultMock())
                expect(sut).toNot(beNil())
            }
        }
        
        describe("consume") {
            context("initial") {
                it("consumes change") {
                    let change = ServiceGrantChange.initialWithState(.init(requestingServiceGrantIDs:[]))
                    let changeAfterConsume = sut.consume(change: change)
                    expect(changeAfterConsume).to(beNil())
                }
            }
        }
    }
}
