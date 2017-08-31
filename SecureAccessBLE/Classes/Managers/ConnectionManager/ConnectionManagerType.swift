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

    var sentData: PublishSubject<Error?> { get }
    var receivedData: PublishSubject<Result<Data>> { get }

    func connectToSorc(_ sorcID: SorcID)
    func disconnect()
    func sendData(_ data: Data)
}
