//
//  SessionManagerConfiguration.swift
//  SecureAccessBLE
//
//  Created on 06.09.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

extension SessionManager {
    struct Configuration {
        let heartbeatInterval: TimeInterval
        let heartbeatTimeout: TimeInterval
        /** Maximum number of messages which can be enqueued.

            Generally, every message which gets enqueued is dequeued immediately if the session layer is not in a state waiting for message respond.
            Q: Why is this queue bounding necessary and how should it be sized?
            A: It is especially important for the case where the user executes multiple requests simultaneously, e.g. in one synchronous loop.
            This can happen deliberately - if e.g. a lock/lockStatus/immo/immostatus sequence is sent - or by mistake.
            In this case, if the maximum is reached, the messages won't be ebqueued.
            It is possible to define large numbers like e.g. 100 (this was actually successfully tested in a stress test)
            but it can lead to issues if the requests take too long because the same queue is used for heart beat messages.
            That means it can happen that the CAM receives the next heart beat message only after 100 messages are processed.
            The number should be chosen to satisfy a realistic use cases. How much messages would a user need to enqueue at once?
         **/
        let maximumEnqueuedMessages: Int

        init(
            heartbeatInterval: TimeInterval? = nil,
            heartbeatTimeout: TimeInterval? = nil,
            maximumEnqueuedMessages: Int? = nil
        ) {
            self.heartbeatInterval = heartbeatInterval ?? 2
            self.heartbeatTimeout = heartbeatTimeout ?? 6
            self.maximumEnqueuedMessages = maximumEnqueuedMessages ?? 10
        }
    }
}
