public extension UniqueID {
    @inlinable @inline(never)
    init?<UTF8Bytes: BidirectionalCollection>(
        utf8: UTF8Bytes
    ) where UTF8Bytes.Element == UInt8 {
        
        var utf8 = utf8[...]
        // Trim curly braces.
        if utf8.first == 0x7B /* "{" */ {
            guard utf8.last == 0x7D /* "}" */ else {
                return nil
            }
            utf8 = utf8.dropFirst().dropLast()
        }
        // Parse the bytes.
        var tuple = UniqueID.zero.tuple
        let success = withUnsafeMutableBytes(of: &tuple) { uuidBytes -> Bool in
            var i = utf8.startIndex
            for storagePosition in 0..<16 {
                while i < utf8.endIndex, utf8[i] == 0x2D /* "-" */ {
                    utf8.formIndex(after: &i)
                }
                guard let parsedByte = utf8.parseByte(at: &i) else {
                    return false
                }
                uuidBytes[storagePosition] = parsedByte
            }
            return i == utf8.endIndex
        }
        guard success else { return nil }
        self = UniqueID(tuple: tuple)
    }
}

@usableFromInline internal let DC: Int8 = -1

@usableFromInline internal let hex_table: [Int8] = [
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC, // 48 invalid chars.
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC,
    00, 01, 02, 03, 04, 05, 06, 07, 08, 09, // numbers 0-9
    DC, DC, DC, DC, DC, DC, DC,             // 7 invalid chars from ':' to '@'
    10, 11, 12, 13, 14, 15,                 // uppercase A-F
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC, // 20 invalid chars G-Z
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC,                 // 6 invalid chars from '[' to '`'
    10, 11, 12, 13, 14, 15,                 // lowercase a-f
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC, // 20 invalid chars g-z
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC,                     // 5 invalid chars from '{' to '(delete)'
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC, // 128 non-ASCII chars.
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC, DC, DC, DC,
    DC, DC, DC, DC, DC, DC, DC,
]

// Returns the numeric value of the hex digit `ascii`, if it is a hex digit (0-9, A-F, a-f).
@inlinable
internal func asciiToHex(_ ascii: UInt8) -> UInt8? {
    let numericValue = hex_table.withUnsafeBufferPointer { $0[Int(ascii)] }
    return numericValue < 0 ? nil : UInt8(bitPattern: numericValue)
}

extension Collection where Element == UInt8 {
    @inlinable
    internal func parseByte(at i: inout Index) -> UInt8? {
        guard i < endIndex, let firstNibble = asciiToHex(self[i]) else { return nil }
        formIndex(after: &i)
        guard i < endIndex, let secondNibble = asciiToHex(self[i]) else { return nil }
        formIndex(after: &i)
        return (firstNibble &<< 4) | secondNibble
    }
}
