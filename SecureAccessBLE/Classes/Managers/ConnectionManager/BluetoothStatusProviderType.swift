//
//  BluetoothStatusProviderType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

protocol BluetoothStatusProviderType {
    var isBluetoothEnabled: BehaviorSubject<Bool> { get }
}
