//
//  BluetoothStatusProviderType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils
import Foundation

protocol BluetoothStatusProviderType {
    var isBluetoothEnabled: BehaviorSubject<Bool> { get }
}
