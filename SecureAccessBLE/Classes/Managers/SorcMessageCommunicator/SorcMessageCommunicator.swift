//
//  SorcMessageCommunicator.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import Foundation
import CommonUtils

/// Sends and receives SORC messages. Handles encryption/decryption.
class SorcMessageCommunicator {

    enum Error: Swift.Error, CustomStringConvertible {
        case receivedInvalidData

        var description: String {
            return "Invalid data was received."
        }
    }

    let messageReceived = PublishSubject<Result<SorcMessage>>()

    var isBusy: Bool {
        return dataCommunicator.isBusy
    }

    var isEncryptionEnabled: Bool {
        return cryptoManager is AesCbcCryptoManager
    }

    private let dataCommunicator: SorcDataCommunicator
    private var cryptoManager: CryptoManager = ZeroSecurityManager()
    private let disposeBag = DisposeBag()

    init(dataCommunicator: SorcDataCommunicator) {
        self.dataCommunicator = dataCommunicator

        dataCommunicator.dataReceived.subscribeNext { [weak self] data in
            guard let strongSelf = self else { return }
            guard data.count > 0 else {
                strongSelf.messageReceived.onNext(.error(Error.receivedInvalidData))
                return
            }

            let message = strongSelf.cryptoManager.decryptData(data)
            guard message.id != .notValid else {
                strongSelf.messageReceived.onNext(.error(Error.receivedInvalidData))
                return
            }

            strongSelf.updateMTUSizeIfReceived(message: message)

            strongSelf.messageReceived.onNext(.success(message))
        }
        .disposed(by: disposeBag)
    }

    /**
     Sends data over the transporter
     When previous data is still in a sending state, the method will return **false** and an error message.
     Otherwise it will return **true** and a no error string (nil)

     - parameter message: The SorcMessage which should be send

     - returns:  (success: Bool, error: String?) A Tuple containing a success boolean and a error string or nil
     */
    func sendMessage(_ message: SorcMessage) -> (success: Bool, error: String?) {
        if dataCommunicator.isBusy {
            print("Sending package not empty!! Message \(message.id) will not be sent!!")
            return (false, "Sending in progress")
        } else {
            let data = cryptoManager.encryptMessage(message)
            return dataCommunicator.sendData(data)

            /*
             print("Send Encrypted Message: \(data.toHexString())")
             print("Same message decrypted: \(self.cryptoManager.decryptData(data).data.toHexString())")
             let key = NSData.withBytes(self.cryptoManager.key)
             print("With key: \(key.toHexString())")
             */
        }
    }

    func enableEncryption(withSessionKey key: [UInt8]) {
        cryptoManager = AesCbcCryptoManager(key: key)
    }

    func reset() {
        dataCommunicator.resetCurrentPackage()
        cryptoManager = ZeroSecurityManager()
    }

    // MARK: Private methods

    private func updateMTUSizeIfReceived(message: SorcMessage) {
        if case .mtuReceive = message.id, let mtuSize = MTUSize(rawData: message.message).mtuSize {
            dataCommunicator.mtuSize = mtuSize
        }
    }
}
