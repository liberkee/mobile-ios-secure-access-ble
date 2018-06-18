//
//  SorcManagerConfiguration.swift
//  SecureAccessBLE
//
//  Created on 08.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension SorcManager {

    // MARK: - Configuration

    /// The configuration for the `SorcManager`
    public struct Configuration {
        /// The time interval a heartbeat is sent to the SORC
        public let heartbeatInterval: TimeInterval?

        /// The time interval after a connection is terminated if the SORC does not respond within the given interval
        public let heartbeatTimeout: TimeInterval?

        /// The maximum number of messages that can be queued up until an error is notified
        public let maximumEnqueuedMessages: Int?

        /// The service ID the SORC uses
        public let serviceID: String?

        /// The ID of the notify characteristic the SORC uses
        public let notifyCharacteristicID: String?

        /// The ID of the write characteristic the SORC uses
        public let writeCharacteristicID: String?

        /// The duration a SORC is considered outdated if last discovery date is longer ago than this duration
        public let sorcOutdatedDuration: TimeInterval?

        /// The interval a timer is triggered to remove outdated discovered SORCs
        public let removeOutdatedSorcsInterval: TimeInterval?

        /// :nodoc:
        public init(
            heartbeatInterval: TimeInterval? = nil,
            heartbeatTimeout: TimeInterval? = nil,
            maximumEnqueuedMessages: Int? = nil,
            serviceID: String? = nil,
            notifyCharacteristicID: String? = nil,
            writeCharacteristicID: String? = nil,
            sorcOutdatedDuration: TimeInterval? = nil,
            removeOutdatedSorcsInterval: TimeInterval? = nil
        ) {
            self.heartbeatInterval = heartbeatInterval
            self.heartbeatTimeout = heartbeatTimeout
            self.maximumEnqueuedMessages = maximumEnqueuedMessages
            self.serviceID = serviceID
            self.notifyCharacteristicID = notifyCharacteristicID
            self.writeCharacteristicID = writeCharacteristicID
            self.sorcOutdatedDuration = sorcOutdatedDuration
            self.removeOutdatedSorcsInterval = removeOutdatedSorcsInterval
        }
    }
}
