public extension UniqueID {
    @inlinable
    static func random() -> UniqueID {
        var rng = SystemRandomNumberGenerator()
        return random(using: &rng)
    }
}

extension UniqueID {
    @inlinable
    internal static func random<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UniqueID {
        var storage = UniqueID.zero.tuple
        withUnsafeMutableBytes(of: &storage) { bytes in
            var random = rng.next()
            withUnsafePointer(to: &random) {
                bytes.baseAddress!.copyMemory(from: UnsafeRawPointer($0), byteCount: 8)
            }
            random = rng.next()
            withUnsafePointer(to: &random) {
                bytes.baseAddress!.advanced(by: 8).copyMemory(from: UnsafeRawPointer($0), byteCount: 8)
            }
        }
        // octet 6 = time_hi_and_version (high octet).
        // high 4 bits = version number.
        storage.6 = (storage.6 & 0xF) | 0x40
        // octet 8 = clock_seq_high_and_reserved.
        // high 2 bits = variant (10 = standard).
        storage.8 = (storage.8 & 0x3F) | 0x80
        return UniqueID(tuple: storage)
    }
}
