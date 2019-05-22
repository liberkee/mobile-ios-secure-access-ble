// KeyholderManager.swift
// TACS

// Created on 03.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import CoreBluetooth
import Foundation
import SecureAccessBLE

public class KeyholderManager: NSObject, KeyholderManagerType {
    private let keyholderChangeSubject = ChangeSubject<KeyholderStatusChange>(state: .stopped)
    public var keyholderChange: ChangeSignal<KeyholderStatusChange> {
        return keyholderChangeSubject.asSignal()
    }

    private let centralManager: CBCentralManagerType
    private let queue: DispatchQueue
    internal var keyholderIDProvider: (() -> UUID?)!

    private let keyholderServiceId = "180A"
    private var scanTimeoutTimer: RepeatingBackgroundTimer?

    required init(centralManager: CBCentralManagerType, queue: DispatchQueue) {
        self.centralManager = centralManager
        self.queue = queue
        super.init()
        self.centralManager.delegate = self
    }

    public func requestStatus(timeout: TimeInterval) {
        queue.async {
            self.requestStatusInternal(timeout: timeout)
        }
    }

    internal func requestStatusInternal(timeout: TimeInterval) {
        guard keyholderIDProvider() != nil else {
            let change = KeyholderStatusChange(state: .stopped, action: .failed(.keyholderIdMissing))
            keyholderChangeSubject.onNext(change)
            return
        }
        guard centralManager.state == .poweredOn else {
            let change = KeyholderStatusChange(state: .stopped, action: .failed(.bluetoothOff))
            keyholderChangeSubject.onNext(change)
            return
        }

        let cbuuid = CBUUID(string: keyholderServiceId)
        centralManager.scanForPeripherals(withServices: [cbuuid], options: nil)
        scheduleTimeoutTimer(timeout: timeout)
        let change = KeyholderStatusChange(state: .searching, action: .discoveryStarted)
        keyholderChangeSubject.onNext(change)
    }

    private func scheduleTimeoutTimer(timeout: TimeInterval) {
        scanTimeoutTimer = RepeatingBackgroundTimer.scheduledTimer(timeInterval: timeout, queue: queue, handler: onTimeout)
    }

    private func onTimeout() {
        scanTimeoutTimer?.suspend()
        centralManager.stopScan()
        let change = KeyholderStatusChange(state: .stopped, action: .failed(.scanTimeout))
        keyholderChangeSubject.onNext(change)
    }

    func centralManager_(_: CBCentralManagerType, didDiscover _: CBPeripheralType,
                         advertisementData: [String: Any], rssi _: NSNumber) {
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
            let keyholderInfo = KeyholderInfo(manufacturerData: manufacturerData),
            keyholderInfo.keyholderId == keyholderIDProvider() {
            onKeyholderDiscovered(keyholderInfo: keyholderInfo)
        }
    }

    private func onKeyholderDiscovered(keyholderInfo: KeyholderInfo) {
        scanTimeoutTimer?.suspend()
        centralManager.stopScan()
        let change = KeyholderStatusChange(state: .stopped, action: .discovered(keyholderInfo))
        keyholderChangeSubject.onNext(change)
    }
}

extension KeyholderManager {
    public convenience init(queue: DispatchQueue) {
        let centralManager = CBCentralManager(delegate: nil, queue: queue,
                                              options: [CBPeripheralManagerOptionShowPowerAlertKey: 0])
        self.init(centralManager: centralManager, queue: queue)
    }
}

extension KeyholderManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_: CBCentralManager) {}

     public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                                advertisementData: [String: Any], rssi RSSI: NSNumber) {
        centralManager_(central as CBCentralManagerType,
                        didDiscover: peripheral as CBPeripheralType,
                        advertisementData: advertisementData,
                        rssi: RSSI)
    }
}
