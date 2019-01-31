//
//  MD5.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 06/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

final class MD5: HashProtocol {
    var size: Int = 16 // 128 / 8
    let message: NSData

    init(_ message: NSData) {
        self.message = message
    }

    /** specifies the per-round shift amounts */
    private let s: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    ]

    /** binary integer part of the sines of integers (Radians) */
    private let k: [UInt32] = [
        0xD76A_A478, 0xE8C7_B756, 0x2420_70DB, 0xC1BD_CEEE,
        0xF57C_0FAF, 0x4787_C62A, 0xA830_4613, 0xFD46_9501,
        0x6980_98D8, 0x8B44_F7AF, 0xFFFF_5BB1, 0x895C_D7BE,
        0x6B90_1122, 0xFD98_7193, 0xA679_438E, 0x49B4_0821,
        0xF61E_2562, 0xC040_B340, 0x265E_5A51, 0xE9B6_C7AA,
        0xD62F_105D, 0x2441453, 0xD8A1_E681, 0xE7D3_FBC8,
        0x21E1_CDE6, 0xC337_07D6, 0xF4D5_0D87, 0x455A_14ED,
        0xA9E3_E905, 0xFCEF_A3F8, 0x676F_02D9, 0x8D2A_4C8A,
        0xFFFA_3942, 0x8771_F681, 0x6D9D_6122, 0xFDE5_380C,
        0xA4BE_EA44, 0x4BDE_CFA9, 0xF6BB_4B60, 0xBEBF_BC70,
        0x289B_7EC6, 0xEAA1_27FA, 0xD4EF_3085, 0x4881D05,
        0xD9D4_D039, 0xE6DB_99E5, 0x1FA2_7CF8, 0xC4AC_5665,
        0xF429_2244, 0x432A_FF97, 0xAB94_23A7, 0xFC93_A039,
        0x655B_59C3, 0x8F0C_CC92, 0xFFEF_F47D, 0x8584_5DD1,
        0x6FA8_7E4F, 0xFE2C_E6E0, 0xA301_4314, 0x4E08_11A1,
        0xF753_7E82, 0xBD3A_F235, 0x2AD7_D2BB, 0xEB86_D391
    ]

    private let h: [UInt32] = [0x6745_2301, 0xEFCD_AB89, 0x98BA_DCFE, 0x1032_5476]

    func calculate() -> NSData {
        let tmpMessage = prepare(64)

        // hash values
        var hh = h

        // Step 2. Append Length a 64-bit representation of lengthInBits
        let lengthInBits = (message.length * 8)
        let lengthBytes = lengthInBits.bytes(64 / 8)
        tmpMessage.appendBytes(Array(lengthBytes.reverse())) // FIXME: Array?

        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        for chunk in NSDataSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15
            var M = [UInt32](count: 16, repeatedValue: 0)
            let range = NSRange(location: 0, length: M.count * sizeof(UInt32))
            chunk.getBytes(UnsafeMutablePointer<Void>(M), range: range)

            // Initialize hash value for this chunk:
            var A: UInt32 = hh[0]
            var B: UInt32 = hh[1]
            var C: UInt32 = hh[2]
            var D: UInt32 = hh[3]

            var dTemp: UInt32 = 0

            // Main loop
            for j in 0 ..< k.count {
                var g = 0
                var F: UInt32 = 0

                switch j {
                case 0 ... 15:
                    F = (B & C) | ((~B) & D)
                    g = j
                case 16 ... 31:
                    F = (D & B) | (~D & C)
                    g = (5 * j + 1) % 16
                case 32 ... 47:
                    F = B ^ C ^ D
                    g = (3 * j + 5) % 16
                case 48 ... 63:
                    F = C ^ (B | (~D))
                    g = (7 * j) % 16
                default:
                    break
                }
                dTemp = D
                D = C
                C = B
                B = B &+ rotateLeft((A &+ F &+ k[j] &+ M[g]), n: s[j])
                A = dTemp
            }

            hh[0] = hh[0] &+ A
            hh[1] = hh[1] &+ B
            hh[2] = hh[2] &+ C
            hh[3] = hh[3] &+ D
        }

        let buf: NSMutableData = NSMutableData()
        hh.forEach({ (item) -> Void in
            var i: UInt32 = item.littleEndian
            buf.appendBytes(&i, length: sizeofValue(i))
        })

        return buf.copy() as! NSData
    }
}
