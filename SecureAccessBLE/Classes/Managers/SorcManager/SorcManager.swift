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

    /// The bluetooth status
    public var bluetoothState: StateSignal<BluetoothState> {
        return bluetoothStatusProvider.bluetoothState.asSignal()
    }

    // MARK: - Discovery

    /// Starts discovery of SORCs
    public func startDiscovery() {
        HSMTrack(.discoveryStartedByApp,
                 loglevel: .info)
        HSMLog(message: "BLE - Scanner started discovery", level: .verbose)
        scanner.startDiscovery()
    }

    /// Stops discovery of SORCs
    public func stopDiscovery() {
        HSMTrack(.discoveryCancelledbyApp,
                 loglevel: .info)
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
        HSMTrack(.connectionStartedByApp,
                 parameters: [ParameterKey.sorcID.rawValue: leaseToken.sorcID],
                 loglevel: .info)
        HSMLog(message: "BLE - Connected to SORC", level: .verbose)
        sessionManager.connectToSorc(leaseToken: leaseToken, leaseTokenBlob: leaseTokenBlob)
    }

    /**
     Disconnects from current SORC
     */
    public func disconnect() {
        HSMLog(message: "BLE - Disconnected", level: .verbose)
        HSMTrack(.connectionCancelledByApp,
                 loglevel: .info)
        sessionManager.disconnect()
    }

    // MARK: - Service

    /// The state of service grant requesting with the action that led to this state
    public var serviceGrantChange: ChangeSignal<ServiceGrantChange> {
        return serviceGrantChangeSubject.asSignal()
    }

    private var serviceGrantChangeSubject = ChangeSubject<ServiceGrantChange>(state: .init(requestingServiceGrantIDs: []))
    fileprivate let disposeBag = DisposeBag()

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
        setUpTracking()
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
        HSMTrack(.interfaceInitialized, loglevel: .info)
    }
}

// MARK: - Tracking

extension SorcManager {
    fileprivate func setUpTracking() {
        connectionChange.subscribe { change in
            switch change.action {
            case let .connect(sorcID: sorcId):
                HSMTrack(.connectionStarted,
                         parameters: [ParameterKey.sorcID.rawValue: sorcId],
                         loglevel: .info)
            case let .connectingFailed(sorcID: sorcId, error: error):
                HSMTrack(.connectionDisconnected,
                         parameters: [ParameterKey.sorcID.rawValue: sorcId,
                                      ParameterKey.error.rawValue: String(describing: error)],
                         loglevel: .error)
            case let .connectionLost(error: error):
                HSMTrack(.connectionDisconnected,
                         parameters: [ParameterKey.error.rawValue: String(describing: error)],
                         loglevel: .error)
            case let .connectionEstablished(sorcID: sorcId):
                HSMTrack(.connectionEstablished,
                         parameters: [ParameterKey.sorcID.rawValue: sorcId],
                         loglevel: .info)

            case .initial:
                break
            case .physicalConnectionEstablished:
                // TODO: Shouldn't we track that?
                break
            case .disconnect:
                // We track this in discovery change since we get the sorc id there
                break
            }
        }.disposed(by: disposeBag)

        discoveryChange.subscribe { change in
            switch change.action {
            case .startDiscovery:
                HSMTrack(.discoveryStarted, loglevel: .info)
            case .stopDiscovery:
                HSMTrack(.discoveryStopped, loglevel: .info)
            case let .lost(sorcIDs: sorcIDs):
                let params = [ParameterKey.sorcIDs.rawValue: sorcIDs.map { $0.uuidString }]
                HSMTrack(.discoveryLost, parameters: params, loglevel: .info)
            case let .discovered(sorcID: sorcId):
                HSMTrack(.discoverySorcDiscovered,
                         parameters: [ParameterKey.sorcID.rawValue: sorcId],
                         loglevel: .info)
            case let .disconnected(sorcID: sorcId):
                HSMTrack(.connectionDisconnected,
                         parameters: [ParameterKey.sorcID.rawValue: sorcId],
                         loglevel: .info)
            case .initial, .rediscovered, .reset, .disconnect:
                break
            }
        }.disposed(by: disposeBag)
    }
}
