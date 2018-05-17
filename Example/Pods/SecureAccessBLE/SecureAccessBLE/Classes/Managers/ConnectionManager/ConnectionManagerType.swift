//
//  ConnectionManagerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils
import CoreBluetooth

protocol ConnectionManagerType {
    var connectionChange: ChangeSubject<PhysicalConnectionChange> { get }

    func connectToSorc(_ sorcID: SorcID)
    func disconnect()

    var dataSent: PublishSubject<Error?> { get }
    var dataReceived: PublishSubject<Result<Data>> { get }

    func sendData(_ data: Data)
}
