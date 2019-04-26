// TelematicsManagerDefaultMock.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.


@testable import TACS
import SecureAccessBLE

class TelematicsManagerDefaultMock: TelematicsManagerType {
    var changeAfterConsume: ServiceGrantChange?
    func consume(change: ServiceGrantChange) -> ServiceGrantChange? {
        return changeAfterConsume
    }
    
    func requestTelematicsData(_ types: [TelematicsDataType]) {
    }
    var telematicsDataChangeSubject = ChangeSubject<TelematicsDataChange>(state: [])
    var telematicsDataChange: ChangeSignal<TelematicsDataChange> {
        return telematicsDataChangeSubject.asSignal()
    }
}
