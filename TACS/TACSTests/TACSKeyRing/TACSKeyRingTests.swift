// TACSKeyRingTests.swift
// TACSTests

// Created on 02.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick
@testable import TACS

class TACSKeyRingTests: QuickSpec {
    override func spec() {
        describe("init from json") {
            it("should map") {
                let url = Bundle(for: TACSKeyRingTests.self).url(forResource: "KeyRingUpdatedEvent", withExtension: "json")!
                let json = try! String(contentsOf: url).data(using: .utf8)!
                let sut = try! JSONDecoder().decode(TACSKeyRing.self, from: json)
                expect(sut).toNot(beNil())
            }
        }
    }
}
