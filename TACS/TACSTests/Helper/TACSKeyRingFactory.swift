// TACSKeyRingFactory.swift
// TACSTests

// Created on 02.05.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.

import Foundation
import TACS

class TACSKeyRingFactory {
    static func validDefaultKeyRing() -> TACSKeyRing {
        let url = Bundle(for: TACSKeyRingTests.self).url(forResource: "KeyRingUpdatedEvent", withExtension: "json")!
        let json = try! String(contentsOf: url).data(using: .utf8)!
        return try! JSONDecoder().decode(TACSKeyRing.self, from: json)
    }
}
