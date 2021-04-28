//
//  AES.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 21/11/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//

import Foundation

public final class AES {
    enum Error: ErrorType {
        case BlockSizeExceeded
    }

    public enum AESVariant: Int {
        case aes128 = 1, aes192, aes256

        var Nk: Int { // Nk words
            return [4, 6, 8][rawValue - 1]
        }

        var Nb: Int { // Nb words
            return 4
        }

        var Nr: Int { // Nr
            return Nk + 6
        }
    }

    public let blockMode: CipherBlockMode
    public static let blockSize: Int = 16 // 128 /8

    public var variant: AESVariant {
        switch key.count * 8 {
        case 128:
            return .aes128
        case 192:
            return .aes192
        case 256:
            return .aes256
        default:
            preconditionFailure("Unknown AES variant for given key.")
        }
    }

    private let key: [UInt8]
    private let iv: [UInt8]?
    public lazy var expandedKey: [UInt8] = { AES.expandKey(self.key, variant: self.variant) }()

    private static let sBox: [UInt8] = [
        0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76,
        0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0,
        0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15,
        0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75,
        0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84,
        0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF,
        0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8,
        0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2,
        0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73,
        0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB,
        0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79,
        0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08,
        0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A,
        0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E,
        0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF,
        0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16
    ]

    private static let invSBox: [UInt8] = [
        0x52, 0x09, 0x6A, 0xD5, 0x30, 0x36, 0xA5, 0x38, 0xBF, 0x40, 0xA3,
        0x9E, 0x81, 0xF3, 0xD7, 0xFB, 0x7C, 0xE3, 0x39, 0x82, 0x9B, 0x2F,
        0xFF, 0x87, 0x34, 0x8E, 0x43, 0x44, 0xC4, 0xDE, 0xE9, 0xCB, 0x54,
        0x7B, 0x94, 0x32, 0xA6, 0xC2, 0x23, 0x3D, 0xEE, 0x4C, 0x95, 0x0B,
        0x42, 0xFA, 0xC3, 0x4E, 0x08, 0x2E, 0xA1, 0x66, 0x28, 0xD9, 0x24,
        0xB2, 0x76, 0x5B, 0xA2, 0x49, 0x6D, 0x8B, 0xD1, 0x25, 0x72, 0xF8,
        0xF6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xD4, 0xA4, 0x5C, 0xCC, 0x5D,
        0x65, 0xB6, 0x92, 0x6C, 0x70, 0x48, 0x50, 0xFD, 0xED, 0xB9, 0xDA,
        0x5E, 0x15, 0x46, 0x57, 0xA7, 0x8D, 0x9D, 0x84, 0x90, 0xD8, 0xAB,
        0x00, 0x8C, 0xBC, 0xD3, 0x0A, 0xF7, 0xE4, 0x58, 0x05, 0xB8, 0xB3,
        0x45, 0x06, 0xD0, 0x2C, 0x1E, 0x8F, 0xCA, 0x3F, 0x0F, 0x02, 0xC1,
        0xAF, 0xBD, 0x03, 0x01, 0x13, 0x8A, 0x6B, 0x3A, 0x91, 0x11, 0x41,
        0x4F, 0x67, 0xDC, 0xEA, 0x97, 0xF2, 0xCF, 0xCE, 0xF0, 0xB4, 0xE6,
        0x73, 0x96, 0xAC, 0x74, 0x22, 0xE7, 0xAD, 0x35, 0x85, 0xE2, 0xF9,
        0x37, 0xE8, 0x1C, 0x75, 0xDF, 0x6E, 0x47, 0xF1, 0x1A, 0x71, 0x1D,
        0x29, 0xC5, 0x89, 0x6F, 0xB7, 0x62, 0x0E, 0xAA, 0x18, 0xBE, 0x1B,
        0xFC, 0x56, 0x3E, 0x4B, 0xC6, 0xD2, 0x79, 0x20, 0x9A, 0xDB, 0xC0,
        0xFE, 0x78, 0xCD, 0x5A, 0xF4, 0x1F, 0xDD, 0xA8, 0x33, 0x88, 0x07,
        0xC7, 0x31, 0xB1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xEC, 0x5F, 0x60,
        0x51, 0x7F, 0xA9, 0x19, 0xB5, 0x4A, 0x0D, 0x2D, 0xE5, 0x7A, 0x9F,
        0x93, 0xC9, 0x9C, 0xEF, 0xA0, 0xE0, 0x3B, 0x4D, 0xAE, 0x2A, 0xF5,
        0xB0, 0xC8, 0xEB, 0xBB, 0x3C, 0x83, 0x53, 0x99, 0x61, 0x17, 0x2B,
        0x04, 0x7E, 0xBA, 0x77, 0xD6, 0x26, 0xE1, 0x69, 0x14, 0x63, 0x55,
        0x21, 0x0C, 0x7D
    ]

    // Parameters for Linear Congruence Generators
    private static let Rcon: [UInt8] = [
        0x8D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36, 0x6C, 0xD8, 0xAB, 0x4D, 0x9A,
        0x2F, 0x5E, 0xBC, 0x63, 0xC6, 0x97, 0x35, 0x6A, 0xD4, 0xB3, 0x7D, 0xFA, 0xEF, 0xC5, 0x91, 0x39,
        0x72, 0xE4, 0xD3, 0xBD, 0x61, 0xC2, 0x9F, 0x25, 0x4A, 0x94, 0x33, 0x66, 0xCC, 0x83, 0x1D, 0x3A,
        0x74, 0xE8, 0xCB, 0x8D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36, 0x6C, 0xD8,
        0xAB, 0x4D, 0x9A, 0x2F, 0x5E, 0xBC, 0x63, 0xC6, 0x97, 0x35, 0x6A, 0xD4, 0xB3, 0x7D, 0xFA, 0xEF,
        0xC5, 0x91, 0x39, 0x72, 0xE4, 0xD3, 0xBD, 0x61, 0xC2, 0x9F, 0x25, 0x4A, 0x94, 0x33, 0x66, 0xCC,
        0x83, 0x1D, 0x3A, 0x74, 0xE8, 0xCB, 0x8D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B,
        0x36, 0x6C, 0xD8, 0xAB, 0x4D, 0x9A, 0x2F, 0x5E, 0xBC, 0x63, 0xC6, 0x97, 0x35, 0x6A, 0xD4, 0xB3,
        0x7D, 0xFA, 0xEF, 0xC5, 0x91, 0x39, 0x72, 0xE4, 0xD3, 0xBD, 0x61, 0xC2, 0x9F, 0x25, 0x4A, 0x94,
        0x33, 0x66, 0xCC, 0x83, 0x1D, 0x3A, 0x74, 0xE8, 0xCB, 0x8D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20,
        0x40, 0x80, 0x1B, 0x36, 0x6C, 0xD8, 0xAB, 0x4D, 0x9A, 0x2F, 0x5E, 0xBC, 0x63, 0xC6, 0x97, 0x35,
        0x6A, 0xD4, 0xB3, 0x7D, 0xFA, 0xEF, 0xC5, 0x91, 0x39, 0x72, 0xE4, 0xD3, 0xBD, 0x61, 0xC2, 0x9F,
        0x25, 0x4A, 0x94, 0x33, 0x66, 0xCC, 0x83, 0x1D, 0x3A, 0x74, 0xE8, 0xCB, 0x8D, 0x01, 0x02, 0x04,
        0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36, 0x6C, 0xD8, 0xAB, 0x4D, 0x9A, 0x2F, 0x5E, 0xBC, 0x63,
        0xC6, 0x97, 0x35, 0x6A, 0xD4, 0xB3, 0x7D, 0xFA, 0xEF, 0xC5, 0x91, 0x39, 0x72, 0xE4, 0xD3, 0xBD,
        0x61, 0xC2, 0x9F, 0x25, 0x4A, 0x94, 0x33, 0x66, 0xCC, 0x83, 0x1D, 0x3A, 0x74, 0xE8, 0xCB, 0x8D
    ]

    public init?(key: [UInt8], iv: [UInt8], blockMode: CipherBlockMode = .CBC) {
        self.key = key
        self.iv = iv
        self.blockMode = blockMode

        if blockMode.needIV, iv.count != AES.blockSize {
            assert(false, "Block size and Initialization Vector must be the same length!")
            return nil
        }
    }

    public convenience init?(key: [UInt8], blockMode: CipherBlockMode = .CBC) {
        // default IV is all 0x00...
        let defaultIV = [UInt8](count: AES.blockSize, repeatedValue: 0)
        self.init(key: key, iv: defaultIV, blockMode: blockMode)
    }

    public convenience init?(key: String, iv: String, blockMode: CipherBlockMode = .CBC) {
        if let kkey = key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.arrayOfBytes(), let iiv = iv.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)?.arrayOfBytes() {
            self.init(key: kkey, iv: iiv, blockMode: blockMode)
        } else {
            return nil
        }
    }

    /**
     Encrypt message. If padding is necessary, then PKCS7 padding is added and needs to be removed after decryption.

     - parameter message: Plaintext data

     - returns: Encrypted data
     */

    public func encrypt(bytes: [UInt8], padding: Padding? = PKCS7()) throws -> [UInt8] {
        var finalBytes = bytes

        if let padding = padding {
            finalBytes = padding.add(bytes, blockSize: AES.blockSize)
        } else if bytes.count % AES.blockSize != 0 {
            throw Error.BlockSizeExceeded
        }

        let blocks = finalBytes.chunks(AES.blockSize) // 0.34
        return try blockMode.encryptBlocks(blocks, iv: iv, cipherOperation: encryptBlock)
    }

    private func encryptBlock(block: [UInt8]) -> [UInt8]? {
        var out = [UInt8]()

        autoreleasepool { () -> Void in
            var state = [[UInt8]](count: variant.Nb, repeatedValue: [UInt8](count: variant.Nb, repeatedValue: 0))
            for (i, row) in state.enumerate() {
                for (j, _) in row.enumerate() {
                    state[j][i] = block[i * row.count + j]
                }
            }

            state = addRoundKey(state, expandedKey, 0)

            for roundCount in 1 ..< variant.Nr {
                subBytes(&state)
                state = shiftRows(state)
                state = mixColumns(state)
                state = addRoundKey(state, expandedKey, roundCount)
            }

            subBytes(&state)
            state = shiftRows(state)
            state = addRoundKey(state, expandedKey, variant.Nr)

            out = [UInt8](count: state.count * state.first!.count, repeatedValue: 0)
            for i in 0 ..< state.count {
                for j in 0 ..< state[i].count {
                    out[(i * 4) + j] = state[j][i]
                }
            }
        }
        return out
    }

    public func decrypt(bytes: [UInt8], padding: Padding? = PKCS7()) throws -> [UInt8] {
        if bytes.count % AES.blockSize != 0 {
            throw Error.BlockSizeExceeded
        }

        let blocks = bytes.chunks(AES.blockSize)
        let out: [UInt8]
        switch blockMode {
        case .CFB, .CTR:
            // CFB, CTR uses encryptBlock to decrypt
            out = try blockMode.decryptBlocks(blocks, iv: iv, cipherOperation: encryptBlock)
        default:
            out = try blockMode.decryptBlocks(blocks, iv: iv, cipherOperation: decryptBlock)
        }

        if let padding = padding {
            return padding.remove(out, blockSize: nil)
        }

        return out
    }

    private func decryptBlock(block: [UInt8]) -> [UInt8]? {
        var state = [[UInt8]](count: variant.Nb, repeatedValue: [UInt8](count: variant.Nb, repeatedValue: 0))
        for (i, row) in state.enumerate() {
            for (j, _) in row.enumerate() {
                state[j][i] = block[i * row.count + j]
            }
        }

        state = addRoundKey(state, expandedKey, variant.Nr)

        for roundCount in (1 ..< variant.Nr).reverse() {
            state = invShiftRows(state)
            state = invSubBytes(state)
            state = addRoundKey(state, expandedKey, roundCount)
            state = invMixColumns(state)
        }

        state = invShiftRows(state)
        state = invSubBytes(state)
        state = addRoundKey(state, expandedKey, 0)

        var out = [UInt8]()
        for i in 0 ..< state.count {
            for j in 0 ..< state[0].count {
                out.append(state[j][i])
            }
        }

        return out
    }

    private static func expandKey(key: [UInt8], variant: AESVariant) -> [UInt8] {
        /*
         * Function used in the Key Expansion routine that takes a four-byte
         * input word and applies an S-box to each of the four bytes to
         * produce an output word.
         */
        func subWord(word: [UInt8]) -> [UInt8] {
            var result = word
            for i in 0 ..< 4 {
                result[i] = sBox[Int(word[i])]
            }
            return result
        }

        var w = [UInt8](count: variant.Nb * (variant.Nr + 1) * 4, repeatedValue: 0)
        for i in 0 ..< variant.Nk {
            for wordIdx in 0 ..< 4 {
                w[(4 * i) + wordIdx] = key[(4 * i) + wordIdx]
            }
        }

        var tmp: [UInt8]
        for var i = variant.Nk; i < variant.Nb * (variant.Nr + 1); i++ {
            tmp = [UInt8](count: 4, repeatedValue: 0)

            for wordIdx in 0 ..< 4 {
                tmp[wordIdx] = w[4 * (i - 1) + wordIdx]
            }
            if (i % variant.Nk) == 0 {
                let rotWord = rotateLeft(UInt32.withBytes(tmp), n: 8).bytes(sizeof(UInt32)) // RotWord
                tmp = subWord(rotWord)
                tmp[0] = tmp[0] ^ Rcon[i / variant.Nk]
            } else if variant.Nk > 6, (i % variant.Nk) == 4 {
                tmp = subWord(tmp)
            }

            // xor array of bytes
            for wordIdx in 0 ..< 4 {
                w[4 * i + wordIdx] = w[4 * (i - variant.Nk) + wordIdx] ^ tmp[wordIdx]
            }
        }
        return w
    }
}

public extension AES {
    // byte substitution with table (S-box)
    func subBytes(inout state: [[UInt8]]) {
        for (i, row) in state.enumerate() {
            for (j, value) in row.enumerate() {
                state[i][j] = AES.sBox[Int(value)]
            }
        }
    }

    func invSubBytes(state: [[UInt8]]) -> [[UInt8]] {
        var result = state
        for (i, row) in state.enumerate() {
            for (j, value) in row.enumerate() {
                result[i][j] = AES.invSBox[Int(value)]
            }
        }
        return result
    }

    // Applies a cyclic shift to the last 3 rows of a state matrix.
    func shiftRows(state: [[UInt8]]) -> [[UInt8]] {
        var result = state
        for r in 1 ..< 4 {
            for c in 0 ..< variant.Nb {
                result[r][c] = state[r][(c + r) % variant.Nb]
            }
        }
        return result
    }

    func invShiftRows(state: [[UInt8]]) -> [[UInt8]] {
        var result = state
        for r in 1 ..< 4 {
            for c in 0 ..< variant.Nb {
                result[r][(c + r) % variant.Nb] = state[r][c]
            }
        }
        return result
    }

    // Multiplies two polynomials
    func multiplyPolys(a: UInt8, _ b: UInt8) -> UInt8 {
        var a = a, b = b
        var p: UInt8 = 0, hbs: UInt8 = 0

        for _ in 0 ..< 8 {
            if b & 1 == 1 {
                p ^= a
            }
            hbs = a & 0x80
            a <<= 1
            if hbs > 0 {
                a ^= 0x1B
            }
            b >>= 1
        }
        return p
    }

    func matrixMultiplyPolys(matrix: [[UInt8]], _ array: [UInt8]) -> [UInt8] {
        var returnArray = [UInt8](count: array.count, repeatedValue: 0)
        for (i, row) in matrix.enumerate() {
            for (j, boxVal) in row.enumerate() {
                returnArray[i] = multiplyPolys(boxVal, array[j]) ^ returnArray[i]
            }
        }
        return returnArray
    }

    func addRoundKey(state: [[UInt8]], _ expandedKeyW: [UInt8], _ round: Int) -> [[UInt8]] {
        var newState = [[UInt8]](count: state.count, repeatedValue: [UInt8](count: variant.Nb, repeatedValue: 0))
        let idxRow = 4 * variant.Nb * round
        for c in 0 ..< variant.Nb {
            let idxCol = variant.Nb * c
            newState[0][c] = state[0][c] ^ expandedKeyW[idxRow + idxCol + 0]
            newState[1][c] = state[1][c] ^ expandedKeyW[idxRow + idxCol + 1]
            newState[2][c] = state[2][c] ^ expandedKeyW[idxRow + idxCol + 2]
            newState[3][c] = state[3][c] ^ expandedKeyW[idxRow + idxCol + 3]
        }
        return newState
    }

    // mixes data (independently of one another)
    func mixColumns(state: [[UInt8]]) -> [[UInt8]] {
        var state = state
        let colBox: [[UInt8]] = [[2, 3, 1, 1], [1, 2, 3, 1], [1, 1, 2, 3], [3, 1, 1, 2]]

        var rowMajorState = [[UInt8]](count: state.count, repeatedValue: [UInt8](count: state.first!.count, repeatedValue: 0)) // state.map({ val -> [UInt8] in return val.map { _ in return 0 } }) // zeroing
        var newRowMajorState = rowMajorState

        for i in 0 ..< state.count {
            for j in 0 ..< state[0].count {
                rowMajorState[j][i] = state[i][j]
            }
        }

        for (i, row) in rowMajorState.enumerate() {
            newRowMajorState[i] = matrixMultiplyPolys(colBox, row)
        }

        for i in 0 ..< state.count {
            for j in 0 ..< state[0].count {
                state[i][j] = newRowMajorState[j][i]
            }
        }

        return state
    }

    func invMixColumns(state: [[UInt8]]) -> [[UInt8]] {
        var state = state
        let invColBox: [[UInt8]] = [[14, 11, 13, 9], [9, 14, 11, 13], [13, 9, 14, 11], [11, 13, 9, 14]]

        var colOrderState = state.map { val -> [UInt8] in val.map { _ in 0 } } // zeroing

        for i in 0 ..< state.count {
            for j in 0 ..< state[0].count {
                colOrderState[j][i] = state[i][j]
            }
        }

        var newState = state.map { val -> [UInt8] in val.map { _ in 0 } }

        for (i, row) in colOrderState.enumerate() {
            newState[i] = matrixMultiplyPolys(invColBox, row)
        }

        for i in 0 ..< state.count {
            for j in 0 ..< state[0].count {
                state[i][j] = newState[j][i]
            }
        }

        return state
    }
}
