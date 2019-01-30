//
//  ConnectionManagerConfiguration.swift
//  SecureAccessBLE
//
//  Created on 06.09.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

extension ConnectionManager {
    struct Configuration {
        static let advertisedServiceID = "0x180A"
        static let advertisedCompanyID: [UInt8] = [10, 07]
        static let defaultServiceID = "d1cf0603-b501-4569-a4b9-e47ad3f628a5"
        static let defaultNotifyCharacteristicID = "d1d7a6b6-457e-458a-b237-a9df99b3d98b"
        static let defaultWriteCharacteristicID = "c8e58f23-9417-41c6-97a8-70f6b2c8cab9"
        static let defaultSorcOutdatedDuration = TimeInterval(5)
        static let defaultRemoveOutdatedSorcsInterval = TimeInterval(2)

        let serviceID: String
        let notifyCharacteristicID: String
        let writeCharacteristicID: String
        let sorcOutdatedDuration: TimeInterval
        let removeOutdatedSorcsInterval: TimeInterval

        init(
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
