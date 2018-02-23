//
//  ConnectionManagerConfiguration.swift
//  SecureAccessBLE
//
//  Created on 06.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension ConnectionManager {
    public struct Configuration {
        public static let advertisedServiceID = "0x180A"
        public static let defaultServiceID = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
        public static let defaultNotifyCharacteristicID = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
        public static let defaultWriteCharacteristicID = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
        public static let defaultSorcOutdatedDuration = TimeInterval(5)
        public static let defaultRemoveOutdatedSorcsInterval = TimeInterval(2)

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
            self.serviceID = serviceID ?? Configuration.defaultServiceID
            self.notifyCharacteristicID = notifyCharacteristicID ?? Configuration.defaultNotifyCharacteristicID
            self.writeCharacteristicID = writeCharacteristicID ?? Configuration.defaultWriteCharacteristicID
            self.sorcOutdatedDuration = sorcOutdatedDuration ?? Configuration.defaultSorcOutdatedDuration
            self.removeOutdatedSorcsInterval = removeOutdatedSorcsInterval ?? Configuration.defaultRemoveOutdatedSorcsInterval
        }
    }
}
