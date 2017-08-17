//
//  SorcConnectionManagerType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile. All rights reserved.
//

import CoreBluetooth
import CommonUtils

protocol SorcConnectionManagerType {

    var isPoweredOn: BehaviorSubject<Bool> { get }
    var discoveryChange: ChangeSubject<DiscoveryChange> { get }
    var connectionChange: ChangeSubject<DataConnectionChange> { get }

    var sentData: PublishSubject<Error?> { get }
    var receivedData: PublishSubject<Result<Data>> { get }

    func connectToSorc(_ sorcID: SorcID)
    func disconnect()
    func sendData(_ data: Data)
}
