//
//  AppActivityStatusProvider.swift
//  SecureAccessBLE
//
//  Created on 05.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import UIKit
import CommonUtils

class AppActivityStatusProvider: AppActivityStatusProviderType {

    var appDidBecomeActive: EventSignal<()> {
        return appDidBecomeActiveSubject.asSignal()
    }

    private let appDidBecomeActiveSubject = PublishSubject<()>()

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: Notification.Name.UIApplicationDidBecomeActive,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func handleAppDidBecomeActive() {
        appDidBecomeActiveSubject.onNext()
    }
}
