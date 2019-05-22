// KeyholderManagerDefaultMock.swift
// TACSTests

// Created on 21.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import SecureAccessBLE
import TACS

class KeyholderManagerDefaultMock: KeyholderManagerType {
    func requestStatus(timeout _: TimeInterval) {}
    var keyholderChangeSubject = ChangeSubject<KeyholderStatusChange>(state: .stopped)
    var keyholderChange: ChangeSignal<KeyholderStatusChange> { return keyholderChangeSubject.asSignal() }
}
