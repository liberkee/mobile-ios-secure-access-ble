//
//  SATrackingManagerTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Priya Khatri on 04.02.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE
import XCTest

// swiftlint:disable function_body_length
class SATrackingManagerTests: QuickSpec {
    class CustomTracker: SAEventTracker {
        var receivedEvent: String?
        var receivedParameters: [String: Any]?

        func trackEvent(_ event: String, parameters: [String: Any], loglevel _: LogLevel) {
            receivedEvent = event
            receivedParameters = parameters
        }
    }

    override func spec() {
        var sut: SATrackingManager!
        var customTracker: CustomTracker!
        var systemClock: SystemClockType?

        describe("track") {
            beforeEach {
                let date = Date(timeIntervalSince1970: 0)
                systemClock = SystemClockMock(currentNow: date)
                sut = SATrackingManager(systemClock: systemClock!)
                customTracker = CustomTracker()
                sut.registerTracker(customTracker, logLevel: .info)
            }
            context("usage by external customer") {
                beforeEach {
                    let parameter: [String: Any] = [ParameterKey.sorcID.rawValue: UUID(uuidString: "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f")!]
                    sut.track(.discoveryStartedByApp, parameters: parameter, loglevel: .info)
                }
                it("tracks event") {
                    let expectedEvent = "discoveryStartedByApp"
                    expect(customTracker.receivedEvent) == expectedEvent
                }
                it("has appropriate group") {
                    expect(customTracker.receivedParameters!["group"]! as? String) == "Discovery"
                }
                it("has timestamp") {
                    let expectedDateString = "1970-01-01T00:00:00.000+0000"
                    expect(customTracker.receivedParameters!["timestamp"] as? String) == expectedDateString
                }
                it("has sorciD") {
                    let expectedSorcID = UUID(uuidString: "82f6ed49-b70d-4c9e-afa1-4b0377d0de5f")
                    expect(customTracker.receivedParameters!["sorcID"]! as? UUID) == expectedSorcID
                }
                it("has all default system parameters") {
                    expect(customTracker.receivedParameters!.keys).to(contain(
                        [
                            ParameterKey.os.rawValue,
                            ParameterKey.osVersion.rawValue,
                            ParameterKey.phoneModel.rawValue,
                            ParameterKey.secureAccessFrameworkVersion.rawValue
                        ]))
                }
            }
            context("usage by TACS") {
                beforeEach {
                    sut.usedByTACSSDK = true
                }
                it("tracks events of interest") {
                    sut.track(.connectionTransferringBLOB, loglevel: .info)
                    let expectedEvent = "connectionTransferringBLOB"
                    expect(customTracker.receivedEvent) == expectedEvent
                }
                it("does not track events of no interest") {
                    sut.track(.discoveryStarted, loglevel: .info)
                    expect(customTracker.receivedEvent).to(beNil())
                }
            }
        }
    }
}
