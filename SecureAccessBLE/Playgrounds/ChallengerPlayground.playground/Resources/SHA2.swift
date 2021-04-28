//
//  SHA2.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 24/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

final class SHA2: HashProtocol {
    var size: Int { return variant.rawValue }
    let variant: SHA2.Variant

    let message: NSData

    init(_ message: NSData, variant: SHA2.Variant) {
        self.variant = variant
        self.message = message
    }

    enum Variant: RawRepresentable {
        case sha224, sha256, sha384, sha512

        typealias RawValue = Int
        var rawValue: RawValue {
            switch self {
            case .sha224:
                return 224
            case .sha256:
                return 256
            case .sha384:
                return 384
            case .sha512:
                return 512
            }
        }

        init?(rawValue: RawValue) {
            switch rawValue {
            case 224:
                self = .sha224
            case 256:
                self = .sha256
            case 384:
                self = .sha384
            case 512:
                self = .sha512
            default:
                return nil
            }
        }

        var size: Int { return rawValue }

        private var h: [UInt64] {
            switch self {
            case .sha224:
                return [0xC105_9ED8, 0x367C_D507, 0x3070_DD17, 0xF70E_5939, 0xFFC0_0B31, 0x6858_1511, 0x64F9_8FA7, 0xBEFA_4FA4]
            case .sha256:
                return [0x6A09_E667, 0xBB67_AE85, 0x3C6E_F372, 0xA54F_F53A, 0x510E_527F, 0x9B05_688C, 0x1F83_D9AB, 0x5BE0_CD19]
            case .sha384:
                return [0xCBBB_9D5D_C105_9ED8, 0x629A_292A_367C_D507, 0x9159_015A_3070_DD17, 0x152F_ECD8_F70E_5939, 0x6733_2667_FFC0_0B31, 0x8EB4_4A87_6858_1511, 0xDB0C_2E0D_64F9_8FA7, 0x47B5_481D_BEFA_4FA4]
            case .sha512:
                return [0x6A09_E667_F3BC_C908, 0xBB67_AE85_84CA_A73B, 0x3C6E_F372_FE94_F82B, 0xA54F_F53A_5F1D_36F1, 0x510E_527F_ADE6_82D1, 0x9B05_688C_2B3E_6C1F, 0x1F83_D9AB_FB41_BD6B, 0x5BE0_CD19_137E_2179]
            }
        }

        private var k: [UInt64] {
            switch self {
            case .sha224, .sha256:
                return [
                    0x428A_2F98, 0x7137_4491, 0xB5C0_FBCF, 0xE9B5_DBA5, 0x3956_C25B, 0x59F1_11F1, 0x923F_82A4, 0xAB1C_5ED5,
                    0xD807_AA98, 0x1283_5B01, 0x2431_85BE, 0x550C_7DC3, 0x72BE_5D74, 0x80DE_B1FE, 0x9BDC_06A7, 0xC19B_F174,
                    0xE49B_69C1, 0xEFBE_4786, 0x0FC1_9DC6, 0x240C_A1CC, 0x2DE9_2C6F, 0x4A74_84AA, 0x5CB0_A9DC, 0x76F9_88DA,
                    0x983E_5152, 0xA831_C66D, 0xB003_27C8, 0xBF59_7FC7, 0xC6E0_0BF3, 0xD5A7_9147, 0x06CA_6351, 0x1429_2967,
                    0x27B7_0A85, 0x2E1B_2138, 0x4D2C_6DFC, 0x5338_0D13, 0x650A_7354, 0x766A_0ABB, 0x81C2_C92E, 0x9272_2C85,
                    0xA2BF_E8A1, 0xA81A_664B, 0xC24B_8B70, 0xC76C_51A3, 0xD192_E819, 0xD699_0624, 0xF40E_3585, 0x106A_A070,
                    0x19A4_C116, 0x1E37_6C08, 0x2748_774C, 0x34B0_BCB5, 0x391C_0CB3, 0x4ED8_AA4A, 0x5B9C_CA4F, 0x682E_6FF3,
                    0x748F_82EE, 0x78A5_636F, 0x84C8_7814, 0x8CC7_0208, 0x90BE_FFFA, 0xA450_6CEB, 0xBEF9_A3F7, 0xC671_78F2
                ]
            case .sha384, .sha512:
                return [
                    0x428A_2F98_D728_AE22, 0x7137_4491_23EF_65CD, 0xB5C0_FBCF_EC4D_3B2F, 0xE9B5_DBA5_8189_DBBC, 0x3956_C25B_F348_B538,
                    0x59F1_11F1_B605_D019, 0x923F_82A4_AF19_4F9B, 0xAB1C_5ED5_DA6D_8118, 0xD807_AA98_A303_0242, 0x1283_5B01_4570_6FBE,
                    0x2431_85BE_4EE4_B28C, 0x550C_7DC3_D5FF_B4E2, 0x72BE_5D74_F27B_896F, 0x80DE_B1FE_3B16_96B1, 0x9BDC_06A7_25C7_1235,
                    0xC19B_F174_CF69_2694, 0xE49B_69C1_9EF1_4AD2, 0xEFBE_4786_384F_25E3, 0x0FC1_9DC6_8B8C_D5B5, 0x240C_A1CC_77AC_9C65,
                    0x2DE9_2C6F_592B_0275, 0x4A74_84AA_6EA6_E483, 0x5CB0_A9DC_BD41_FBD4, 0x76F9_88DA_8311_53B5, 0x983E_5152_EE66_DFAB,
                    0xA831_C66D_2DB4_3210, 0xB003_27C8_98FB_213F, 0xBF59_7FC7_BEEF_0EE4, 0xC6E0_0BF3_3DA8_8FC2, 0xD5A7_9147_930A_A725,
                    0x06CA_6351_E003_826F, 0x1429_2967_0A0E_6E70, 0x27B7_0A85_46D2_2FFC, 0x2E1B_2138_5C26_C926, 0x4D2C_6DFC_5AC4_2AED,
                    0x5338_0D13_9D95_B3DF, 0x650A_7354_8BAF_63DE, 0x766A_0ABB_3C77_B2A8, 0x81C2_C92E_47ED_AEE6, 0x9272_2C85_1482_353B,
                    0xA2BF_E8A1_4CF1_0364, 0xA81A_664B_BC42_3001, 0xC24B_8B70_D0F8_9791, 0xC76C_51A3_0654_BE30, 0xD192_E819_D6EF_5218,
                    0xD699_0624_5565_A910, 0xF40E_3585_5771_202A, 0x106A_A070_32BB_D1B8, 0x19A4_C116_B8D2_D0C8, 0x1E37_6C08_5141_AB53,
                    0x2748_774C_DF8E_EB99, 0x34B0_BCB5_E19B_48A8, 0x391C_0CB3_C5C9_5A63, 0x4ED8_AA4A_E341_8ACB, 0x5B9C_CA4F_7763_E373,
                    0x682E_6FF3_D6B2_B8A3, 0x748F_82EE_5DEF_B2FC, 0x78A5_636F_4317_2F60, 0x84C8_7814_A1F0_AB72, 0x8CC7_0208_1A64_39EC,
                    0x90BE_FFFA_2363_1E28, 0xA450_6CEB_DE82_BDE9, 0xBEF9_A3F7_B2C6_7915, 0xC671_78F2_E372_532B, 0xCA27_3ECE_EA26_619C,
                    0xD186_B8C7_21C0_C207, 0xEADA_7DD6_CDE0_EB1E, 0xF57D_4F7F_EE6E_D178, 0x06F0_67AA_7217_6FBA, 0x0A63_7DC5_A2C8_98A6,
                    0x113F_9804_BEF9_0DAE, 0x1B71_0B35_131C_471B, 0x28DB_77F5_2304_7D84, 0x32CA_AB7B_40C7_2493, 0x3C9E_BE0A_15C9_BEBC,
                    0x431D_67C4_9C10_0D4C, 0x4CC5_D4BE_CB3E_42B6, 0x597F_299C_FC65_7E2A, 0x5FCB_6FAB_3AD6_FAEC, 0x6C44_198C_4A47_5817
                ]
            }
        }

        private func resultingArray<T>(hh: [T]) -> [T] {
            var finalHH: [T] = hh
            switch self {
            case .sha224:
                finalHH = Array(hh[0 ..< 7])
            case .sha384:
                finalHH = Array(hh[0 ..< 6])
            default:
                break
            }
            return finalHH
        }
    }

    // FIXME: I can't do Generic func out of calculate32 and calculate64 (UInt32 vs UInt64), but if you can - please do pull request.
    func calculate32() -> NSData {
        let tmpMessage = prepare(64)

        // hash values
        var hh = [UInt32]()
        variant.h.forEach { h -> Void in
            hh.append(UInt32(h))
        }

        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage.appendBytes((message.length * 8).bytes(64 / 8))

        // Process the message in successive 512-bit chunks:
        let chunkSizeBytes = 512 / 8 // 64
        for chunk in NSDataSequence(chunkSize: chunkSizeBytes, data: tmpMessage) {
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 32-bit words into sixty-four 32-bit words:
            var M = [UInt32](count: variant.k.count, repeatedValue: 0)
            for x in 0 ..< M.count {
                switch x {
                case 0 ... 15:
                    var le: UInt32 = 0
                    chunk.getBytes(&le, range: NSRange(location: x * sizeofValue(le), length: sizeofValue(le)))
                    M[x] = le.bigEndian
                default:
                    let s0 = rotateRight(M[x - 15], n: 7) ^ rotateRight(M[x - 15], n: 18) ^ (M[x - 15] >> 3) // FIXME: n
                    let s1 = rotateRight(M[x - 2], n: 17) ^ rotateRight(M[x - 2], n: 19) ^ (M[x - 2] >> 10)
                    M[x] = M[x - 16] &+ s0 &+ M[x - 7] &+ s1
                }
            }

            var A = hh[0]
            var B = hh[1]
            var C = hh[2]
            var D = hh[3]
            var E = hh[4]
            var F = hh[5]
            var G = hh[6]
            var H = hh[7]

            // Main loop
            for j in 0 ..< variant.k.count {
                let s0 = rotateRight(A, n: 2) ^ rotateRight(A, n: 13) ^ rotateRight(A, n: 22)
                let maj = (A & B) ^ (A & C) ^ (B & C)
                let t2 = s0 &+ maj
                let s1 = rotateRight(E, n: 6) ^ rotateRight(E, n: 11) ^ rotateRight(E, n: 25)
                let ch = (E & F) ^ ((~E) & G)
                let t1 = H &+ s1 &+ ch &+ UInt32(variant.k[j]) &+ M[j]

                H = G
                G = F
                F = E
                E = D &+ t1
                D = C
                C = B
                B = A
                A = t1 &+ t2
            }

            hh[0] = (hh[0] &+ A)
            hh[1] = (hh[1] &+ B)
            hh[2] = (hh[2] &+ C)
            hh[3] = (hh[3] &+ D)
            hh[4] = (hh[4] &+ E)
            hh[5] = (hh[5] &+ F)
            hh[6] = (hh[6] &+ G)
            hh[7] = (hh[7] &+ H)
        }

        // Produce the final hash value (big-endian) as a 160 bit number:
        let buf = NSMutableData()
        variant.resultingArray(hh).forEach { item -> Void in
            var i = UInt32(item.bigEndian)
            buf.appendBytes(&i, length: sizeofValue(i))
        }

        return buf.copy() as! NSData
    }

    func calculate64() -> NSData {
        let tmpMessage = prepare(128)

        // hash values
        var hh = [UInt64]()
        variant.h.forEach { h -> Void in
            hh.append(h)
        }

        // append message length, in a 64-bit big-endian integer. So now the message length is a multiple of 512 bits.
        tmpMessage.appendBytes((message.length * 8).bytes(64 / 8))

        // Process the message in successive 1024-bit chunks:
        let chunkSizeBytes = 1024 / 8 // 128
        var leftMessageBytes = tmpMessage.length
        for var i = 0; i < tmpMessage.length; i = i + chunkSizeBytes, leftMessageBytes -= chunkSizeBytes {
            let chunk = tmpMessage.subdataWithRange(NSRange(location: i, length: min(chunkSizeBytes, leftMessageBytes)))
            // break chunk into sixteen 64-bit words M[j], 0 ≤ j ≤ 15, big-endian
            // Extend the sixteen 64-bit words into eighty 64-bit words:
            var M = [UInt64](count: variant.k.count, repeatedValue: 0)
            for x in 0 ..< M.count {
                switch x {
                case 0 ... 15:
                    var le: UInt64 = 0
                    chunk.getBytes(&le, range: NSRange(location: x * sizeofValue(le), length: sizeofValue(le)))
                    M[x] = le.bigEndian
                default:
                    let s0 = rotateRight(M[x - 15], n: 1) ^ rotateRight(M[x - 15], n: 8) ^ (M[x - 15] >> 7)
                    let s1 = rotateRight(M[x - 2], n: 19) ^ rotateRight(M[x - 2], n: 61) ^ (M[x - 2] >> 6)
                    M[x] = M[x - 16] &+ s0 &+ M[x - 7] &+ s1
                }
            }

            var A = hh[0]
            var B = hh[1]
            var C = hh[2]
            var D = hh[3]
            var E = hh[4]
            var F = hh[5]
            var G = hh[6]
            var H = hh[7]

            // Main loop
            for j in 0 ..< variant.k.count {
                let s0 = rotateRight(A, n: 28) ^ rotateRight(A, n: 34) ^ rotateRight(A, n: 39) // FIXME: n:
                let maj = (A & B) ^ (A & C) ^ (B & C)
                let t2 = s0 &+ maj
                let s1 = rotateRight(E, n: 14) ^ rotateRight(E, n: 18) ^ rotateRight(E, n: 41)
                let ch = (E & F) ^ ((~E) & G)
                let t1 = H &+ s1 &+ ch &+ variant.k[j] &+ UInt64(M[j])

                H = G
                G = F
                F = E
                E = D &+ t1
                D = C
                C = B
                B = A
                A = t1 &+ t2
            }

            hh[0] = (hh[0] &+ A)
            hh[1] = (hh[1] &+ B)
            hh[2] = (hh[2] &+ C)
            hh[3] = (hh[3] &+ D)
            hh[4] = (hh[4] &+ E)
            hh[5] = (hh[5] &+ F)
            hh[6] = (hh[6] &+ G)
            hh[7] = (hh[7] &+ H)
        }

        // Produce the final hash value (big-endian)
        let buf = NSMutableData()

        variant.resultingArray(hh).forEach { item -> Void in
            var i = item.bigEndian
            buf.appendBytes(&i, length: sizeofValue(i))
        }

        return buf.copy() as! NSData
    }
}
