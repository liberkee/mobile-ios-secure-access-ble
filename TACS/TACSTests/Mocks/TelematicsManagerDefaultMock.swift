// TelematicsManagerDefaultMock.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import SecureAccessBLE
@testable import TACS

class TelematicsManagerDefaultMock: TelematicsManagerType {
    var changeAfterConsume: ServiceGrantChange?
    func consume(change _: ServiceGrantChange) -> ServiceGrantChange? {
        return changeAfterConsume
    }

    func requestTelematicsData(_: [TelematicsDataType]) {}

    var telematicsDataChangeSubject = ChangeSubject<TelematicsDataChange>(state: [])
    var telematicsDataChange: ChangeSignal<TelematicsDataChange> {
        return telematicsDataChangeSubject.asSignal()
    }
}
