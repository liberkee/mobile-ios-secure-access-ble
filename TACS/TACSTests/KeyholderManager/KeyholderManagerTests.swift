// KeyholderManagerTests.swift
// TACSTests

// Created on 21.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Nimble
import Quick

import CoreBluetooth
@testable import TACS

class KeyholderManagerTests: QuickSpec {
    class CBCentralManagerMock: CBCentralManagerType {
        weak var delegate: CBCentralManagerDelegate?

        var state: CBManagerState = .unknown

        var scanForPeripheralsCalledWithArguments: (serviceUUIDs: [CBUUID]?, options: [String: Any]?)?
        func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
            scanForPeripheralsCalledWithArguments = (serviceUUIDs: serviceUUIDs, options: options)
        }

        var stopScanCalled = false
        func stopScan() {
            stopScanCalled = true
        }

        var connectCalledWithPeripheral: CBPeripheralType?
        func connect(_ peripheral: CBPeripheralType, options _: [String: Any]?) {
            connectCalledWithPeripheral = peripheral
        }

        var cancelConnectionCalledWithPeripheral: CBPeripheralType?
        func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
            cancelConnectionCalledWithPeripheral = peripheral
        }
    }

    class CBPeripheralMock: CBPeripheralType {
        weak var delegate: CBPeripheralDelegate?

        var services_: [CBServiceType]?

        var identifier = UUID()

        var discoverServicesCalledWithUUIDs: [CBUUID]?
        func discoverServices(_ serviceUUIDs: [CBUUID]?) {
            discoverServicesCalledWithUUIDs = serviceUUIDs
        }

        var discoverCharacteristicsCalledWithArguments: (characteristicUUIDs: [CBUUID]?, service: CBServiceType)?
        func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBServiceType) {
            discoverCharacteristicsCalledWithArguments = (characteristicUUIDs, service)
        }

        var writeValueCalledWithArguments: (data: Data, characteristic: CBCharacteristicType,
                                            type: CBCharacteristicWriteType)?
        func writeValue(_ data: Data, for characteristic: CBCharacteristicType, type: CBCharacteristicWriteType) {
            writeValueCalledWithArguments = (data: data, characteristic: characteristic, type: type)
        }

        var setNotifyValueCalledWithArguments: (enabled: Bool, characteristic: CBCharacteristicType)?
        func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicType) {
            setNotifyValueCalledWithArguments = (enabled, characteristic)
        }
    }

    override func spec() {
        var centralManagerMock: CBCentralManagerMock!
        var sut: KeyholderManager!
        var receivedChanges: [KeyholderStatusChange] = []

        beforeEach {
            centralManagerMock = CBCentralManagerMock()
            sut = KeyholderManager(centralManager: centralManagerMock, queue: DispatchQueue.main)
            receivedChanges = []
            _ = sut.keyholderChange.subscribe { change in receivedChanges.append(change) }
            sut.keyholderIDProvider = { nil }
        }

        describe("requestStatus") {
            context("no keyholder id provided") {
                it("notifies failure") {
                    sut.keyholderIDProvider = { nil }
                    sut.requestStatusInternal(timeout: 5.0)
                    expect(receivedChanges).to(haveCount(2))
                    expect(receivedChanges.last) == KeyholderStatusChangeFactory.failedIdMissingChange()
                }
            }

            context("keyholder id provided and device on") {
                beforeEach {
                    sut.keyholderIDProvider = { UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")! }
                    centralManagerMock.state = .poweredOn
                }
                it("starts discovery") {
                    sut.requestStatusInternal(timeout: 5.0)
                    expect(centralManagerMock.scanForPeripheralsCalledWithArguments?.serviceUUIDs?.first?.uuidString) == "180A"
                }
                it("notifies discovery start") {
                    sut.requestStatusInternal(timeout: 5.0)
                    expect(receivedChanges).to(haveCount(2))
                    expect(receivedChanges.last) == KeyholderStatusChange(state: .searching, action: .discoveryStarted)
                }
            }
            context("timeout") {
                it("notifies timeout") {
                    let timeout: TimeInterval = 0.01
                    let expectedTimeoutChange = KeyholderStatusChange(state: .stopped, action: .failed(.scanTimeout))
                    sut.keyholderIDProvider = { UUID(uuidString: "be2fecaf-734b-4252-8312-59d477200a20")! }
                    centralManagerMock.state = .poweredOn
                    sut.requestStatusInternal(timeout: timeout)
                    expect(receivedChanges).toEventually(haveCount(3), timeout: timeout + 0.01)
                    expect(receivedChanges.last).toEventually(equal(expectedTimeoutChange), timeout: timeout)
                }
            }
            context("keyholder discovered") {
                var expectedKeyholderInfo: KeyholderInfo!
                beforeEach {
                    let keyholderID = "7026839CCE854CB1901999B07F56DEFA"
                    sut.keyholderIDProvider = { UUID(hexString: keyholderID)! }
                    centralManagerMock.state = .poweredOn
                    let manufacturerData = ("0A07" + keyholderID + "036000000001010A").dataFromHexadecimalString()!
                    let advertisementData: [String: Any] = [
                        CBAdvertisementDataManufacturerDataKey: manufacturerData
                    ]
                    expectedKeyholderInfo = KeyholderInfo(manufacturerData: manufacturerData)!
                    sut.requestStatusInternal(timeout: 1)
                    sut.centralManager_(centralManagerMock, didDiscover: CBPeripheralMock(), advertisementData: advertisementData, rssi: 60)
                }
                it("notifies discovery") {
                    expect(receivedChanges).to(haveCount(3))
                    expect(receivedChanges.last) == KeyholderStatusChange(state: .stopped, action: .discovered(expectedKeyholderInfo))
                }
                it("stopps discovery") {
                    expect(centralManagerMock.stopScanCalled) == true
                }
            }
        }
    }
}
