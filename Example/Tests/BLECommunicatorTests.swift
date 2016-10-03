//
//  BLECommunicatorTests.swift
//  BLE
//
//  Created by Ke Song on 04.07.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import XCTest

@testable import SecureAccessBLE

class BLECommunicatorTests: XCTestCase {
    
    var communicator = SIDCommunicator.init()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /// To test if the from Scanner found new SIDs will be added to found list
    func testFindNewSidID() {
        /// reset all foundsids
        self.communicator.resetFoundSids()
        
        /// refill all Mock Sids
        self.refillMockSids()
        
        /// the following sids should be found
        XCTAssert(self.communicator.hasSidID("250bf2429d8c4f2896e2030dfe601bd8"), "Communicator has not found NEW Sid")
        
        XCTAssert(self.communicator.hasSidID("550e8400e29b11d4a716446655440003"), "Communicator has not found NEW Sid")
        
        XCTAssert(self.communicator.hasSidID("bb28d13fdcab416b85b7cec28c26add7"), "Communicator has not found NEW Sid")
        
        XCTAssert(self.communicator.hasSidID("1a1092e99f824187af92d92029b28cdc"), "Communicator has not found NEW Sid")
        
        XCTAssert(self.communicator.hasSidID("2c6088153bc7434f9c2b2e3272596adc"), "Communicator has not found NEW Sid")
    }
    
    /// To test the sids older as 5.1 seconds will be filtered
    func testFilterOldSids() {
        /// reset all foundsids
        self.communicator.resetFoundSids()
        
        /// refill all Mock Sids
        self.refillMockSids()
        
        Delay(0.5) {
            /// The old sids will be removed in this case the "250bf2429d8c4f2896e2030dfe601bd8"
            self.communicator.transferShouldFilterOldIds(self.communicator.transporter)
            /// Sid older als 5.1 seconds will be removed
            XCTAssert(self.communicator.hasSidID("250bf2429d8c4f2896e2030dfe601bd8") == false, "Old sid was not filtered from communicator")
        }
        
        Delay(2.5) {
            /// The old sids will be removed in this case the "250bf2429d8c4f2896e2030dfe601bd8"
            self.communicator.transferShouldFilterOldIds(self.communicator.transporter)
            /// Sid older als 5.1 seconds will be removed
            XCTAssert(self.communicator.hasSidID("2c6088153bc7434f9c2b2e3272596adc") == false, "Old sid was not filtered from communicator")
        }
        
    }
    
    /// To test old sid will be replaced with new incomming sid
    func testReplaceSameNewSid() {
        /// reset all foundsids
        self.communicator.resetFoundSids()
        
        /// refill all Mock Sids
        self.refillMockSids()
        
        /// Mock sid id
        let mockSidId = "250bf2429d8c4f2896e2030dfe601bd8"
        
        let reference = NSDate()
        print("reference time: \(reference)")
        
        
        var intervals : [Double] = []// = Array(count: 10, repeatedValue: Double(arc4random_uniform(UInt32(1000))))
        for _ in 0..<100 {
            intervals.append(Double(arc4random_uniform(UInt32(1000))))
        }
        intervals.sortInPlace({ $0 > $1 })
        
        let mockPeripheral = BLEScanner().sidPeripheral
        for interval in intervals {
            let mockSid = SID(sidID: mockSidId, peripheral: mockPeripheral, discoveryDate: reference.dateByAddingTimeInterval(-interval), isConnected: false)
            self.communicator.transferDidDiscoveredSidId(self.communicator.transporter, newSid: mockSid)
        }
        
        let savedSameSids = self.communicator.currentFoundSidIds.filter { (commingSid) -> Bool in
            let sidString = commingSid.sidID
            if sidString.lowercaseString == mockSidId.lowercaseString {
                return true
            } else {
                return false
            }
        }
        
        /// There is only one newest SID saved in Foundlist
        XCTAssert(savedSameSids.count == 1, "The old Sid will be not replaced with new one!")
        
        let justOneSid = savedSameSids[0] as SID
        let smallestTimeInterval = intervals.minElement()
        let sidTime = justOneSid.discoveryDate
        let mustTime = reference.dateByAddingTimeInterval(-smallestTimeInterval!)
        
        /// To test if the one saved SID has newest found time
        XCTAssertEqual(sidTime, mustTime, "The old Sid will be not replaced with new one!")
        
    }
    
    /**
     For tests
     */
    func refillMockSids() {
        let mockPeripheral = BLEScanner().sidPeripheral
        self.communicator.transferDidDiscoveredSidId(self.communicator.transporter, newSid: SID(sidID: "bb28d13fdcab416b85b7cec28c26add7", peripheral: mockPeripheral, discoveryDate: NSDate().dateByAddingTimeInterval(-0.8), isConnected: false))
        self.communicator.transferDidDiscoveredSidId(self.communicator.transporter, newSid: SID(sidID: "550e8400e29b11d4a716446655440003", peripheral: mockPeripheral, discoveryDate: NSDate().dateByAddingTimeInterval(-1.8), isConnected: false))
        self.communicator.transferDidDiscoveredSidId(self.communicator.transporter, newSid: SID(sidID: "1a1092e99f824187af92d92029b28cdc", peripheral: mockPeripheral, discoveryDate: NSDate().dateByAddingTimeInterval(-2.5), isConnected: false))
        self.communicator.transferDidDiscoveredSidId(self.communicator.transporter, newSid: SID(sidID: "2c6088153bc7434f9c2b2e3272596adc", peripheral: mockPeripheral, discoveryDate: NSDate().dateByAddingTimeInterval(-3.0), isConnected: false))
        self.communicator.transferDidDiscoveredSidId(self.communicator.transporter, newSid: SID(sidID: "250bf2429d8c4f2896e2030dfe601bd8", peripheral: mockPeripheral, discoveryDate: NSDate().dateByAddingTimeInterval(-4.8), isConnected: false))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
