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
    var receivedParameters: [String: Any]?

    func trackEvent(_ event: String, parameters: [String: Any], loglevel _: LogLevel) {
        receivedEvent = event
        receivedParameters = parameters
    }
}

class TrackingManagerTests: QuickSpec {
    override func spec() {
        var sut: TrackingManager!
        var customTracker: CustomTracker!

        describe("track") {
            beforeEach {
                sut = TrackingManager()
                customTracker = CustomTracker()
                sut.tracker = customTracker

                let parameter: [String: Any] = [parameterKey.vehicleRef.rawValue: "VEHICLEREFERNCE"]
                sut.track(SAEvent.discoveryStartedByApp, parameters: parameter, loglevel: .info)
            }
            it("tracks event") {
                let expectedEvent = "discoveryStartedByApp"
                expect(customTracker.receivedEvent) == expectedEvent
            }
            it("has appropriate group") {
                expect(customTracker.receivedParameters!["group"]) === "Discovery"
            }
            it("has timestamp") {
                expect(customTracker.receivedParameters!["timestamp"]).toNot(beNil())
            }
            it("has vehicle refernce") {
                let expectedMessage = "VEHICLEREFERNCE"
                expect(customTracker.receivedParameters!["vehicleRef"]! as? String) == expectedMessage
            }
        }
    }
}
