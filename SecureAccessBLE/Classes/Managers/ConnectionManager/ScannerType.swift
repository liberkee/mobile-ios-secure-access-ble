//
//  ScannerType.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation

protocol ScannerType {
    var discoveryChange: ChangeSubject<DiscoveryChange> { get }

//    func startDiscovery(sorcID: SorcID)
    func startDiscovery()
    func stopDiscovery()
}
