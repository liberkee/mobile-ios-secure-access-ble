//
//  BluetoothStatusProviderType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

protocol BluetoothStatusProviderType {
    var isBluetoothEnabled: BehaviorSubject<Bool> { get }
}
