//
//  ConnectionManagerConfiguration.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension ConnectionManager {

    public struct Configuration {

        public let serviceID: String
        public let notifyCharacteristicID: String
        public let writeCharacteristicID: String
        public let sorcOutdatedDuration: TimeInterval
        public let removeOutdatedSorcsInterval: TimeInterval

        public init(
            serviceID: String? = nil,
            notifyCharacteristicID: String? = nil,
            writeCharacteristicID: String? = nil,
            sorcOutdatedDuration: TimeInterval? = nil,
            removeOutdatedSorcsInterval: TimeInterval? = nil
        ) {
            self.serviceID = serviceID ?? "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
            self.notifyCharacteristicID = notifyCharacteristicID ?? "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
            self.writeCharacteristicID = writeCharacteristicID ?? "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
            self.sorcOutdatedDuration = sorcOutdatedDuration ?? 5
            self.removeOutdatedSorcsInterval = removeOutdatedSorcsInterval ?? 2
        }
    }
}
