// TACSManagerTests.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick
import SecureAccessBLE
@testable import TACS

class TACSManagerTests: QuickSpec {
    // swiftlint:disable:next function_body_length
    override func spec() {
        var sorcManager: SorcManagerDefaultMock!
        var sut: TACSManager!
        var receivedConnectionChanges: [TACS.ConnectionChange]!
        var receivedDiscoveryChanges: [TACS.DiscoveryChange]!

        beforeEach {
            sorcManager = SorcManagerDefaultMock()
            let telematicsManager = TelematicsManagerDefaultMock()
            let vehicleAccessManager = VehicleAccessManagerDefaultMock()
            sut = TACSManager(sorcManager: sorcManager,
                              telematicsManager: telematicsManager,
                              vehicleAccessManager: vehicleAccessManager)
            receivedConnectionChanges = []
            _ = sut.connectionChange.subscribe { change in
                receivedConnectionChanges.append(change)
            }
            receivedDiscoveryChanges = []
            _ = sut.discoveryChange.subscribe { change in
                receivedDiscoveryChanges.append(change)
            }
        }
        describe("init") {
            it("should not be nil") {
                expect(sut).toNot(beNil())
            }
        }

        describe("scanForVehicle") {
            context("lease contains data for vehicle") {
                it("starts discovery") {
                    let vehicleRef = "4321"
                    sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: TACSKeyRingFactory.validDefaultKeyRing())
                    expect(sorcManager.didReceiveStartDiscovery) == 1
                }
            }

            context("lease does not contain data for vehicle") {
                beforeEach {
                    let vehicleRef = "NOTEXISTING"
                    sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: TACSKeyRingFactory.validDefaultKeyRing())
                }
                it("does not start discovery") {
                    expect(sorcManager.didReceiveStartDiscovery) == 0
                }
                it("notifies error") {
                    expect(receivedDiscoveryChanges).to(haveCount(2))
                    let expectedChange = TACS.DiscoveryChange(state: .init(discoveredVehicles: VehicleInfos()),
                                                              action: .missingBlobData(vehicleRef: "NOTEXISTING"))
                    expect(receivedDiscoveryChanges.last) == expectedChange
                }
            }

            context("discovery change with known sorc id") {
                it("notifies change with vehicle ref") {
                    let vehicleRef = "4321"
                    sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: TACSKeyRingFactory.validDefaultKeyRing())

                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    let sorcID = keyRing.sorcID(for: vehicleRef)!
                    let sorcInfo = SorcInfo(sorcID: sorcID, discoveryDate: Date(), rssi: 1)
                    let sorcInfoByID = [sorcID: sorcInfo]
                    let sorcInfos = SorcInfos(sorcInfoByID)
                    let state = SecureAccessBLE.DiscoveryChange.State(discoveredSorcs: sorcInfos, discoveryIsEnabled: true)
                    let action = SecureAccessBLE.DiscoveryChange.Action.discovered(sorcID: sorcID)
                    let discoveryChange = SecureAccessBLE.DiscoveryChange(state: state, action: action)
                    sorcManager.discoveryChangeSubject.onNext(discoveryChange)

                    expect(receivedDiscoveryChanges).to(haveCount(2))
                }
            }
        }

        describe("connectToVehicle") {
            context("lease contains data for vehicle") {
                it("starts connecting") {
                    let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                    sut.connect(vehicleAccessGrantId: keyRing.tacsLeaseTokenTable.first!.vehicleAccessGrantId, keyRing: keyRing)
                    let leaseTokenFromKeyRing = keyRing.tacsLeaseTokenTable.first!.leaseToken
                    let blobFromKeyRing = keyRing.tacsSorcBlobTable.first!.blob

                    let expectedToken = try! SecureAccessBLE.LeaseToken(id: leaseTokenFromKeyRing.leaseTokenId.uuidString,
                                                                        leaseID: leaseTokenFromKeyRing.leaseId.uuidString,
                                                                        sorcID: leaseTokenFromKeyRing.sorcId,
                                                                        sorcAccessKey: leaseTokenFromKeyRing.sorcAccessKey)
                    expect(sorcManager.receivedConnectToSorcLeaseToken) == expectedToken
                    let counter = Int(blobFromKeyRing.blobMessageCounter)!
                    let expectedBlob = try! SecureAccessBLE.LeaseTokenBlob(messageCounter: counter, data: blobFromKeyRing.blob)
                    expect(sorcManager.receivedConnectToSorcLeaseTokenBlob) == expectedBlob
                }
            }
            context("on connection change") {
                context("sorcID matches active sorcID") {
                    it("notifies change for vehicle Ref") {
                        let vehicleRef = "4321"
                        let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                        sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: keyRing)
                        let sorcID = keyRing.tacsSorcBlobTable.first!.blob.sorcId
                        let connectionChange = SecureAccessBLE.ConnectionChange(state: .connecting(sorcID: sorcID, state: .physical),
                                                                                action: .connect(sorcID: sorcID))
                        sorcManager.connectionChangeSubject.onNext(connectionChange)

                        let expectedChange = TACS.ConnectionChange(state: .connecting(vehicleRef: vehicleRef, state: .physical),
                                                                   action: .connect(vehicleRef: vehicleRef))

                        expect(receivedConnectionChanges).to(haveCount(2))
                        expect(receivedConnectionChanges.last!) == expectedChange
                    }
                }
                context("sorcID does not match active sorcID") {
                    it("does not notify change") {
                        let vehicleRef = "4321"
                        let keyRing = TACSKeyRingFactory.validDefaultKeyRing()
                        sut.scanForVehicles(vehicleRefs: [vehicleRef], keyRing: keyRing)
                        let sorcID = SorcID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")!
                        let connectionChange = SecureAccessBLE.ConnectionChange(state: .connecting(sorcID: sorcID, state: .physical),
                                                                                action: .connect(sorcID: sorcID))

                        //                    let expectedChange = TACS.ConnectionChange(state: .disconnected,
                        //                                                               action: .connectingFailed(vehicleRef: "NOTEXISTING", error: .leaseDataError))

                        sorcManager.connectionChangeSubject.onNext(connectionChange)
                        expect(receivedConnectionChanges).to(haveCount(1))
                    }
                }
            }
        }
    }
}
