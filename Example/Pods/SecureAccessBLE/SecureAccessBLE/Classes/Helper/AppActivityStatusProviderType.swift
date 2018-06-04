//
//  AppActivityStatusProviderType.swift
//  SecureAccessBLE
//
//  Created on 05.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

protocol AppActivityStatusProviderType {
    var appDidBecomeActive: EventSignal<Bool> { get }
}
