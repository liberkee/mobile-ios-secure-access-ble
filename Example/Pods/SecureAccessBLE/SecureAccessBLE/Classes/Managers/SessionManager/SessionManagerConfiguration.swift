//
//  SessionManagerConfiguration.swift
//  SecureAccessBLE
//
//  Created on 06.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

extension SessionManager {
    struct Configuration {
        let heartbeatInterval: TimeInterval
        let heartbeatTimeout: TimeInterval
        let maximumEnqueuedMessages: Int

        init(
            heartbeatInterval: TimeInterval? = nil,
            heartbeatTimeout: TimeInterval? = nil,
            maximumEnqueuedMessages: Int? = nil
        ) {
            self.heartbeatInterval = heartbeatInterval ?? 2
            self.heartbeatTimeout = heartbeatTimeout ?? 6
            self.maximumEnqueuedMessages = maximumEnqueuedMessages ?? 3
        }
    }
}
