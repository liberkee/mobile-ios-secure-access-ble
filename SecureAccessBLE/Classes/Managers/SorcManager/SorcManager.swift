//
//  SorcManager.swift
//  SecureAccessBLE
//
//  Created on 31.08.17.
//  Copyright © 2018 Huf Secure Mobile GmbH. All rights reserved.
//

/// The manager for discovery, connection and communication with SORCs
public class SorcManager: SorcManagerType {
    private let bluetoothStatusProvider: BluetoothStatusProviderType
    private let scanner: ScannerType
    fileprivate let sessionManager: SessionManagerType
    private var interceptors: [SorcInterceptor] = []

    // MARK: - BLE Interface

    /// The bluetooth enabled status
    public var isBluetoothEnabled: StateSignal<Bool> {
        return bluetoothStatusProvider.isBluetoothEnabled.asSignal()
    }

    // MARK: - Discovery

    /// Starts discovery of SORCs
    public func startDiscovery() {
        HSMLog(message: "BLE - Scanner started discovery", level: .verbose)
        scanner.startDiscovery()
    }

    /// Stops discovery of SORCs
    public func stopDiscovery() {
        HSMLog(message: "BLE - Scanner stopped discovery", level: .verbose)
        scanner.stopDiscovery()
    }

    /// The state of SORC discovery with the action that led to this state
    public var discoveryChange: ChangeSignal<DiscoveryChange> {
        return scanner.discoveryChange.asSignal()
    }

    // MARK: - Connection

    /// The state of the connection with the action that led to this state
    public var connectionChange: ChangeSignal<ConnectionChange> {
        return sessionManager.connectionChange.asSignal()
    }

    /// Connects to a SORC
    ///
    /// - Parameters:
    ///   - leaseToken: The lease token for the SORC
    ///   - leaseTokenBlob: The blob for the SORC
    public func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {
        HSMLog(message: "BLE - Connected to SORC", level: .verbose)
        sessionManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    /**
     Disconnects from current SORC
     */
    public func disconnect() {
        HSMLog(message: "BLE - Disconnected", level: .verbose)
        sessionManager.disconnect()
    }

    // MARK: - Service

    /// The state of service grant requesting with the action that led to this state
    public var serviceGrantChange: ChangeSignal<ServiceGrantChange> {
        return serviceGrantChangeSubject.asSignal()
    }

    private var serviceGrantChangeSubject = ChangeSubject<ServiceGrantChange>(state: .init(requestingServiceGrantIDs: []))
    private let disposeBag = DisposeBag()

    /**
     Requests a service grant from the connected SORC

     - Parameter serviceGrantID: The ID the of the service grant
     */
    public func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        HSMLog(message: "BLE - Request service grant", level: .verbose)
        sessionManager.requestServiceGrant(serviceGrantID)
    }

    init(
        bluetoothStatusProvider: BluetoothStatusProviderType,
        scanner: ScannerType,
        sessionManager: SessionManagerType
    ) {
        self.bluetoothStatusProvider = bluetoothStatusProvider
        self.scanner = scanner
        self.sessionManager = sessionManager
        subscribeToServiceGrantChange()
    }

    private func subscribeToServiceGrantChange() {
        sessionManager.serviceGrantChange.subscribeNext { [weak self] change in
            guard let strongSelf = self else { return }
            var changeAfterInterceptorAppliance: ServiceGrantChange? = change
            for interceptor in strongSelf.interceptors {
                changeAfterInterceptorAppliance = interceptor.consume(change: change)
                if changeAfterInterceptorAppliance == nil {
                    return
                }
            }
            strongSelf.serviceGrantChangeSubject.onNext(change)
        }.disposed(by: disposeBag)
    }

    public func registerInterceptor(_ interceptor: SorcInterceptor) {
        interceptors.append(interceptor)
    }
}

extension SorcManager {
    /// Initializer for `SorcManager`
    ///
    /// After initialization keep a strong reference to this instance as long as you need it.
    /// Note: Only use one instance at a time.
    ///
    /// - Parameter configuration: The configuration for the `SorcManager`
    public convenience init(configuration: SorcManager.Configuration = SorcManager.Configuration(),
                            queue: DispatchQueue = DispatchQueue.main) {
        let connectionConfiguration = ConnectionManager.Configuration(
            serviceID: configuration.serviceID,
            notifyCharacteristicID: configuration.notifyCharacteristicID,
            writeCharacteristicID: configuration.writeCharacteristicID,
            sorcOutdatedDuration: configuration.sorcOutdatedDuration,
            removeOutdatedSorcsInterval: configuration.removeOutdatedSorcsInterval
        )

        let connectionManager = ConnectionManager(configuration: connectionConfiguration, queue: queue)
        let transportManager = TransportManager(connectionManager: connectionManager)
        let securityManager = SecurityManager(transportManager: transportManager)

        let sessionConfiguration = SessionManager.Configuration(
            heartbeatInterval: configuration.heartbeatInterval,
            heartbeatTimeout: configuration.heartbeatTimeout,
            maximumEnqueuedMessages: configuration.maximumEnqueuedMessages
        )

        let sendHeartbeatsTimer: CreateTimer = { block in
            let timer = RepeatingBackgroundTimer(timeInterval: sessionConfiguration.heartbeatInterval, queue: queue)
            timer.eventHandler = block
            return timer
        }

        let checkHeartbeatsResponseTimer: CreateTimer = { block in
            let timer = RepeatingBackgroundTimer(timeInterval: sessionConfiguration.heartbeatInterval, queue: queue)
            timer.eventHandler = block
            return timer
        }

        let sessionManager = SessionManager(securityManager: securityManager,
                                            configuration: sessionConfiguration,
                                            sendHeartbeatsTimer: sendHeartbeatsTimer,
                                            checkHeartbeatsResponseTimer: checkHeartbeatsResponseTimer)

        self.init(
            bluetoothStatusProvider: connectionManager,
            scanner: connectionManager,
            sessionManager: sessionManager
        )
    }
}
