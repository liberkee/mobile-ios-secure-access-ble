//
//  AppActivityStatusProviderType.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils

protocol AppActivityStatusProviderType {
    var appDidBecomeActive: EventSignal<()> { get }
}
