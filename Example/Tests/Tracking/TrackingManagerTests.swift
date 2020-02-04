//
//  TrackingManagerTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Priya Khatri on 04.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE
import XCTest

class CustomTracker: EventTracker {
    var receivedEvent: String?
    var receivedMessage: String?
    var receivedParameters: [String: Any]?

    func trackEvent(_ event: String, message: String, parameters: [String: Any]) {
        receivedEvent = event
        receivedParameters = parameters
        receivedMessage = message
    }
}

class TrackingManagerTests: QuickSpec {
    override func spec() {
        var sut: TrackingManager!
        var customTracker: CustomTracker!

        describe("track") {
//            context("") {
            beforeEach {
                sut = TrackingManager()
                customTracker = CustomTracker()
                sut.tracker = customTracker

                let parameter: [String: Any] = ["vehicleRef": "VEHICLEREFERNCE"]
                sut.track(.discoveryStartedByApp, message: "Discovery action was started by the app", parameters: parameter)
            }
            it("tracks event") {
                let expectedEvent = "discoveryStartedByApp"
                expect(customTracker.receivedEvent) == expectedEvent
            }
            it("has appropriate group") {
                expect(customTracker.receivedParameters!["group"]) === "Discovery"
            }
            it("has appropriate message") {
                let expectedMessage = "Discovery action was started by the app"
                expect(customTracker.receivedMessage) == expectedMessage
            }
            it("has timestamp") {
                expect(customTracker.receivedParameters!["timestamp"]).toNot(beNil())
            }
            it("has vehicle refernce") {
                let expectedMessage = "VEHICLEREFERNCE"
                expect(customTracker.receivedParameters!["vehicleRef"]! as? String) == expectedMessage
            }

//            }
        }
    }
}
