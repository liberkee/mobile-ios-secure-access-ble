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
        var systemClock: SystemClockType?

        describe("track") {
            beforeEach {
                let date = Date(timeIntervalSince1970: 0)
                systemClock = SystemClockMock(currentNow: date)
                sut = TrackingManager(systemClock: systemClock!)
                customTracker = CustomTracker()
                sut.tracker = customTracker

                let parameter: [String: Any] = [ParameterKey.sorcID.rawValue: UUID(uuidString: "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f")!]
                sut.track(SAEvent.discoveryStartedByApp, parameters: parameter, loglevel: .info)
            }
            it("tracks event") {
                let expectedEvent = "discoveryStartedByApp"
                expect(customTracker.receivedEvent) == expectedEvent
            }
            it("has appropriate group") {
                expect(customTracker.receivedParameters!["group"]! as? String) == "Discovery"
            }
            it("has timestamp") {
                let expectedDate = Date(timeIntervalSince1970: 0)
                expect(customTracker.receivedParameters!["timestamp"] as? Date) == expectedDate
            }
            it("has sorciD") {
                let expectedSorcID = UUID(uuidString: "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f")
                expect(customTracker.receivedParameters!["sorcID"]! as? UUID) == expectedSorcID
            }
        }
    }
}
