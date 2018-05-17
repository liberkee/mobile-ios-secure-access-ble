//
//  AppActivityStatusProvider.swift
//  SecureAccessBLE
//
//  Created on 05.09.17.
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import CommonUtils
import UIKit

class AppActivityStatusProvider: AppActivityStatusProviderType {
    var appDidBecomeActive: EventSignal<Bool> {
        return appDidBecomeActiveSubject.asSignal()
    }

    private let appDidBecomeActiveSubject = PublishSubject<Bool>()

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: Notification.Name.UIApplicationDidBecomeActive,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: Notification.Name.UIApplicationDidEnterBackground,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func handleAppDidBecomeActive() {
        appDidBecomeActiveSubject.onNext(true)
    }

    @objc private func handleAppDidEnterBackground() {
        appDidBecomeActiveSubject.onNext(false)
    }
}
