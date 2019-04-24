// SorcInterceptor.swift
// SecureAccessBLE

// Created on 23.04.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

public protocol SorcInterceptor {
    func consume(change: ServiceGrantChange) -> ServiceGrantChange?
}
