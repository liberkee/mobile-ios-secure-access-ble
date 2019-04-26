// SorcManagerMock.swift
// TACSTests

// Created on 25.04.19.
// Copyright © 2019 Huf Secure Mobile. All rights reserved.


import SecureAccessBLE

class SorcManagerDefaultMock: SorcManagerType {
    var isBluetoothEnabledSubject = BehaviorSubject<Bool>(value: true)
    var isBluetoothEnabled: StateSignal<Bool> { return isBluetoothEnabledSubject.asSignal() }
    
    let discoveryChangeSubject = ChangeSubject<DiscoveryChange>(state: .init(
        discoveredSorcs: SorcInfos(),
        discoveryIsEnabled: false
        ))
    
    var discoveryChange: ChangeSignal<DiscoveryChange> { return discoveryChangeSubject.asSignal() }
    
    func startDiscovery() {}
    
    func stopDiscovery() {}
    
    let connectionChangeSubject = ChangeSubject<ConnectionChange>(state: .disconnected)
    
    var connectionChange: ChangeSignal<ConnectionChange> { return connectionChangeSubject.asSignal() }
    
    func connectToSorc(leaseToken: LeaseToken, leaseTokenBlob: LeaseTokenBlob) {}
    
    func disconnect() {}
    
    let serviceGrantChangeSubject = ChangeSubject<ServiceGrantChange>(state: .init(requestingServiceGrantIDs: []))
    var serviceGrantChange: ChangeSignal<ServiceGrantChange> { return serviceGrantChangeSubject.asSignal() }
    
    var didRequestServiceGrant = 0
    func requestServiceGrant(_ serviceGrantID: ServiceGrantID) {
        didRequestServiceGrant += 1
    }
    
    var didReceiveRegisterInterceptor = 0
    var receivedRegisterInterceptorInterceptors: [SorcInterceptor] = []
    func registerInterceptor(_ interceptor: SorcInterceptor) {
        didReceiveRegisterInterceptor += 1
        receivedRegisterInterceptorInterceptors.append(interceptor)
    }
}
