//
//  ScannerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

protocol ScannerType {
    var discoveryChange: ChangeSubject<DiscoveryChange> { get }

    func startDiscovery()
    func stopDiscovery()
}
