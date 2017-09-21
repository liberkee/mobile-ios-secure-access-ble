//
//  ConnectionManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CoreBluetooth
import CommonUtils

protocol ConnectionManagerType {

    var connectionChange: ChangeSubject<PhysicalConnectionChange> { get }

    func connectToSorc(_ sorcID: SorcID)
    func disconnect()

    var dataSent: PublishSubject<Error?> { get }
    var dataReceived: PublishSubject<Result<Data>> { get }

    func sendData(_ data: Data)
}