// BLEDiscoveryChangeFactory.swift
// TACSTests

// Created on 03.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE

class BLEDiscoveryChangeFactory {
    static func discoveredChange(with sorcID: SorcID, date: Date = Date()) -> DiscoveryChange {
        let sorcInfo = SorcInfo(sorcID: sorcID, discoveryDate: date, rssi: 1)
        let sorcInfoByID = [sorcID: sorcInfo]
        let sorcInfos = SorcInfos(sorcInfoByID)
        let state = SecureAccessBLE.DiscoveryChange.State(discoveredSorcs: sorcInfos, discoveryIsEnabled: true)
        let action = SecureAccessBLE.DiscoveryChange.Action.discovered(sorcID: sorcID)
        let discoveryChange = SecureAccessBLE.DiscoveryChange(state: state, action: action)
        return discoveryChange
    }
}
