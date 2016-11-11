//
//  BLEManagerTests.swift
//  BLE
//
//  Created by Ke Song on 06.07.16.
//  Copyright © 2016 Huf Secure Mobile. All rights reserved.
//

import XCTest

@testable import SecureAccessBLE

import CryptoSwift

/// Testing for BLE manager
class BLEManagerTests: XCTestCase {
    /// blescanner instance
    let bleScanner = BLEScanner()
    /// ble communicator instance
    let bleCommunicator = SIDCommunicator()
    /// ble manager instance
    let bleManager = BLEComManager(crypto: false)
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
     To test changing connection state in scanner and communicator, and corresposing changed connetion states for BLE-manager
     */
    func testChangingConnectionState() {
        
        /// scanner will set to unconnected
        self.bleScanner.isConnected = false
        
        /// scanner update state and reports connection state
        self.bleScanner.centralManagerDidUpdateState(bleScanner.centralManager)
        
        /// blemanager is not connected, because the scanner not connected
        XCTAssertFalse(self.bleManager.isConnected, "BLE manager has wrong connection state")
        
        self.bleCommunicator.delegate = self.bleManager
        /// change transfer connection status to connected
        self.bleCommunicator.transferDidChangedConnectionState(self.bleScanner, isConnected: true)
        
        /// ble manager is not connected because crypto was Not established even with connected scanner
        XCTAssertFalse(self.bleManager.isConnected, "BLE manager has wrong connection state")
        
        /// Mock session key for crypto
        let mockSessionKey = [0xa9,0xba,0x14,0xa1,0x50,0x20,0x9f,0xe2,0x30,0xe7,0x1a,0x2b,0x78,0x0f,0x06,0x45] as [UInt8]
        
        /// To change crypto status in blemanager
        self.bleManager.challengerFinishedWithSessionKey(mockSessionKey)
        
        /// The blemanager must be now connected because scanner connected and crypto established
        XCTAssertTrue(self.bleManager.isConnected, "BLE manager has wrong connection state")
        
    }
    
    /**
     To test ble manager sending and receiving message
     */
    func testSendingAndReceivingMessage() {
        /// MTURequest message
        let mtuMessage = SIDMessage(id: SIDMessageID.mtuRequest, payload: MTUSize())
        
        /// Sending the MTURequest message
        let sendingSuccess = self.bleManager.sendMessage(mtuMessage)
        
        /// Tests if sending success
        XCTAssertTrue(sendingSuccess.success == true, "BLE manager did failed by sending MTURequest")
        
        /// Tests if sending error is NIL
        XCTAssertNil(sendingSuccess.error, "BLE manager did failed by sending MTURequest")
        
        /// Communicator reports receiving response data for MTU Response
        self.bleCommunicator.delegate = self.bleManager
        
        /// MTU response data with size
        let bytes = [0x07, 0x9b, 0x00] as [UInt8]
        self.bleCommunicator.delegate?.communicatorDidRecivedData(NSData(bytes: bytes, length: bytes.count) as Data, count: 1)
        
        /// MTU size for ios device is default 155
        XCTAssertEqual(BLEComManager.mtuSize, 155, "BLE manager has wrong MTU Size number!")
    }
    
    /**
     To test ble manager sending and receiving service Grant
     */
    func testSendingAndReceivingServiceGrant() {
        /// Mock session key for crypto
        let mockSessionKey = [0xa9,0xba,0x14,0xa1,0x50,0x20,0x9f,0xe2,0x30,0xe7,0x1a,0x2b,0x78,0x0f,0x06,0x45] as [UInt8]
        //let mockSessionKey = Cipher.randomIV(16) as [UInt8]
        
        /// Ble manager with established AES crypto manager
        self.bleManager.challengerFinishedWithSessionKey(mockSessionKey)
        
        /// Service grant for .Lockstatus will sent to SID
        let payload = ServiceGrantRequest(grantID: ServiceGrantID.lockStatus)
        let message = SIDMessage(id: SIDMessageID.serviceGrant, payload: payload)
        
        /// Sending is success or not
        let sendingSuccess = self.bleManager.sendMessage(message)
        
        /// Test if sending error was NIL
        XCTAssertNil(sendingSuccess.error, "Sending service grant message did failed!")
        
        /// Test if sending if success
        XCTAssertTrue(sendingSuccess.success, "Sending service grant message did failed!")
        
        self.bleCommunicator.delegate = self.bleManager
        
        /// Mock data with service trigger status Locked
        let mockBytes = [0xd3,0x7d,0x36,0x92,0xbe,0xb0,0xf2,0xde,0x36,0xd8,0x75,0xf9,0xbb,0x4c,0xf3,0x00,0xf5,0xf9,0x54,0x83,0x62,0x54,0xbf,0xaf] as [UInt8]
        let mockReceivedData = NSData(bytes: mockBytes, length: mockBytes.count)
        
        /// ble manager will be reported for receiving data
        self.bleCommunicator.delegate?.communicatorDidRecivedData(mockReceivedData as Data, count: mockReceivedData.length / 4)
        
        /// AES cryptor will initialized
        var cryptor = AesCbcCryptoManager(key: mockSessionKey)
        /// The received data must be decrpted
        let receivedMessage = cryptor.decryptData(mockReceivedData as Data)
        
        /// service grant trigger builded from received message
        let serviceGrantTrigger = ServiceGrantTrigger(rawData: receivedMessage.message)
        
        /// Testing if service grant trigger has ID .Lockstatus
        XCTAssertEqual(serviceGrantTrigger.id, ServiceGrantID.lockStatus, "BLE manager received wrong service grant ID!")
        
        /// Testing if service grant trigger has result .Locked
        XCTAssertEqual(serviceGrantTrigger.result, ServiceGrantTrigger.ServiceGrantResult.Locked, "BLE manager received wrong service grant result!")
        
    }
    
    
    func testSendingBlob() {
        /// Mock session key for crypto
        
        let mockSessionKey = [0x11,0x78,0x78,0x78,0x3c,0x13,0xb2,0x86,0x78,0x78,0x58,0x78,0x23,0xab,0x78] as [UInt8]
        
        /// Ble manager with established AES crypto manager
        self.bleManager.challengerFinishedWithSessionKey(mockSessionKey)
        
        /// Mock blob data for sending message
        let mockBlobData = "ASUL8kKdjE8oluIDDf5gG9gBAR0EAABk7qoX/DOQLkqSiekGa8Qif9oaLZFDT7hwQnTV4/in+63QEkOImLL0lu0hxrXy6U732cNU2m4eeEHtOaQuecEURgtD32S6Al2WDEuA891mJv/wbbexa2y1OprUef9WyO7xvvkeSGX0nnfaoPbpPePJJxqI/E/yaQyayQD8TLQqd9q4IYFoOxlchlKic/2nE7Hyvx+5oLIREipxIb92A8J8vGKLhDOglGFlI2QAIhe9vFRnCJ3r1TQ+ulsnLiyQ3OByChBp3rnQ0h9KnLWmiRYOHcZIRHGILPlBDaMYWp1lsvL86zqzyKMXjQ2u8I3kqrKanSOqQkoh4MvYbF+hXvO/nQf9yT6cdnr4sZKjLUOBqzBRnprK1D45f8tU6CMjqssc7o/iqwlWrouKHcr8vWatt9o82AyMSWm7O36UHUEdr29wbFgwTQNH0fOkuOOoy+Nf69MbD8oJeuwFFgXjrbW8coEHgUr7La2R5IW+HHGA+HaFrsWPMPJrqsUdcGIe8nPErmby2bhKu98AGcYYWdbFZHJ4fx4SBAW5sR5hgkx8Tj4IC/WVe0uUStbgVemxnviPSDAL8NkefytZbXEdWxxXyYagFnVb3Y+JXosh07LcuZswGc9uOlGm5b3yjQgB9gJyzs2kGIhLw6yiQhl8KYqsDr3cZitxv9c7eLOf1CzyLjMI0RU14qadxqQl/aOdIvY0r3MTmJmCTtFQyKXJ7xKWk2rBFA5dRTjq99Nw9w6weHN7mWBmuP7+SMMdeP6bcqnVq4BMc9Y/jpf6fjcPTdSsdMY4884m2zWOl1xU29uR9Zz5vi6SodJCXgdyYMXp3Uu7aYLsUVpQz0/FHGJbK9XZHJKMqgsooktSVf3ByCCK7OyFi3L4VU5BD/nCLUDiC1TzjfXRUSJCYFoVqIGaVm3ngtV9JjsZk3kjrXayv8fTzs+ytm/Q2/+NPl3v80CBSrgljdkKt2DORY38pkANSemnh6atWL2u318ORSqRS7qb5gqwZ6US9e4lkHz9dgmeMWbmMxrE9MM0XFfFFDK4Cx/hxkeelAQb7HT50GE1EWpUgF+CMBXm4d6t3XFHlpI4r7NjJp6gysLwl/O1859PurQV5F7kgrmATxF9+Xf76t6jzNbrjkwIC5RtV3K2FYR5H3ani2vJRKpkzPfpaChZUb8M"
        
        /// To build sending blob message
        let payload = LTBlobPayload(blobData: mockBlobData)
        let blobMessage = SIDMessage(id: .ltBlob, payload: payload!)
        
        /// Sending success
        let sendingSuccess = self.bleManager.sendMessage(blobMessage)
        
        /// Test if sending error was NIL
        XCTAssertNil(sendingSuccess.error, "Sending Lease token blob message did failed!")
        
        /// Test if sending if success
        XCTAssertTrue(sendingSuccess.success, "Sending Lease token blob message did failed!")
    }
    
    
    func testPerformanceExample() {
        self.measure {
        }
    }
    
    
        
}