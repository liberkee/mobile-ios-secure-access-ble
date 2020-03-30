//
//  PhoneToSorcChallengeTests.swift
//  SecureAccessBLE_Tests
//
//  Created by Oleg Langer on 27.03.20.
//  Copyright © 2020 Huf Secure Mobile GmbH. All rights reserved.
//

import Nimble
import Quick
@testable import SecureAccessBLE

// swiftlint:disable line_length
class PhoneToSorcChallengeTests: QuickSpec {
    override func spec() {
        let leaseID = "93763982-4cc0-4974-b138-230fdac6786c"
        let sorcID = SorcID(uuidString: "2AE58E31-E8B0-4260-AFA3-E5F8BF2D5E07")!
        let leaseTokenID = "b9a0f517-096c-4a6a-b88d-bc5d7d4bb73d"
        let challenge = [UInt8](repeating: 0x00, count: 16)

        var sut: PhoneToSorcChallenge!
        beforeEach {
            sut = PhoneToSorcChallenge(leaseID: leaseID, sorcID: sorcID, leaseTokenID: leaseTokenID, challenge: challenge)
        }
        it("creates data sequence") {
            let expectedRawDataHexString = "39333736333938322d346363302d343937342d623133382d32333066646163363738366332616535386533312d653862302d343236302d616661332d65356638626632643565303762396130663531372d303936632d346136612d623838642d62633564376434626237336400000000000000000000000000000000"
            expect(sut.data.bytes.toHexString()) == expectedRawDataHexString
        }
        it("has leaseID") {
            expect(sut.leaseID) == leaseID
        }
        it("has sorcID") {
            expect(sut.sorcID) == sorcID
        }
        it("has leaseTokenID") {
            expect(sut.leaseTokenID) == leaseTokenID
        }
        it("has challenge") {
            expect(sut.challenge) == challenge
        }
    }
}
