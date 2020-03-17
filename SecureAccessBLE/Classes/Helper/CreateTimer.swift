// CreateTimer.swift
// SecureAccessBLE

// Created on 12.07.19.
// Copyright © 2019 Huf Secure Mobile GmbH. All rights reserved.

import Foundation

typealias CreateTimer = (@escaping () -> Void) -> RepeatingBackgroundTimer

typealias CreateRestartableTimer = (@escaping () -> Void) -> BackgroundTimer
