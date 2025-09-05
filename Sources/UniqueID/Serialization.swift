public extension UniqueID {
    func serialized(
        uppercase: Bool = false, separators: Bool = true
    ) -> String {
        let capacity = 32 + (separators ? 4 : 0)
        let buffer = [UInt8](unsafeUninitializedCapacity: capacity) { buffer, count in
            count = serialize(into: buffer, uppercase: uppercase, separators: separators)
        }
        return String(decoding: buffer, as: UTF8.self)
    }
    
    internal func serialize(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        uppercase: Bool, separators: Bool
    ) -> Int {
        // format = 8-4-4-4-12
        withUnsafeBytes(of: tuple) { octets in
            var i = 0
            // 8:
            for octetPosition in 0..<4 {
                i = buffer.writeHex(octets[octetPosition], at: i, uppercase: uppercase)
            }
            if separators {
                i = buffer.writeDash(at: i)
            }
            // 4:
            for octetPosition in 4..<6 {
                i = buffer.writeHex(octets[octetPosition], at: i, uppercase: uppercase)
            }
            if separators {
                i = buffer.writeDash(at: i)
            }
            // 4:
            for octetPosition in 6..<8 {
                i = buffer.writeHex(octets[octetPosition], at: i, uppercase: uppercase)
            }
            if separators {
                i = buffer.writeDash(at: i)
            }
            // 4:
            for octetPosition in 8..<10 {
                i = buffer.writeHex(octets[octetPosition], at: i, uppercase: uppercase)
            }
            if separators {
                i = buffer.writeDash(at: i)
            }
            // 12:
            for octetPosition in 10..<16 {
                i = buffer.writeHex(octets[octetPosition], at: i, uppercase: uppercase)
            }
            return i
        }
    }
}

extension UnsafeMutableBufferPointer where Element == UInt8 {
    internal func writeHex_uppercase(_ value: UInt8, at i: Index) -> Index {
        let table: StaticString = "0123456789ABCDEF"
        table.withUTF8Buffer { table in
            self[i] = table[Int(value &>> 4)]
            self[i &+ 1] = table[Int(value & 0xF)]
        }
        return i &+ 2
    }
    
    internal func writeHex_lowercase(_ value: UInt8, at i: Index) -> Index {
        let table: StaticString = "0123456789abcdef"
        table.withUTF8Buffer { table in
            self[i] = table[Int(value &>> 4)]
            self[i &+ 1] = table[Int(value & 0xF)]
        }
        return i &+ 2
    }
    
    internal func writeHex(_ value: UInt8, at i: Index, uppercase: Bool) -> Index {
        uppercase ? writeHex_uppercase(value, at: i): writeHex_lowercase(value, at: i)
    }
    
    internal func writeDash(at i: Index) -> Index {
        self[i] = 0x2D
        return i &+ 1
    }
}
