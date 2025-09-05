#if canImport(Synchronization)
import Timestamp
import Synchronization

@usableFromInline
internal class UUIDv6GeneratorState {
    @usableFromInline
    internal var timestamp: Timestamp
    @usableFromInline
    internal var sequence: UInt16
    
    init() {
        self.timestamp = 0
        // Seed the value, so sequence numbers start from a random spot.
        // Adds another little bit of spatial uniqueness, while preserving locality.
        var rng = SystemRandomNumberGenerator()
        self.sequence = rng.next() & 0x3fff
    }
}

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@usableFromInline
internal let state = Mutex(UUIDv6GeneratorState())

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
public extension UniqueID {
    @inlinable
    static func timeOrdered() -> UniqueID {
        var rng = SystemRandomNumberGenerator()
        return timeOrdered(using: &rng)
    }
    
    @inlinable
    internal static func timeOrdered<RNG: RandomNumberGenerator>(using rng: inout RNG) -> UniqueID {
        // Set the IEEE 802 multicast bit for random node-IDs, as recommended by RFC-4122.
        let node = rng.next() | 0x0000_0100_0000_0000
        return timeOrdered(node: node)
    }
    
    @inlinable
    internal static func timeOrdered(rawTimestamp: UInt64, sequence: UInt16 = 0, node: UInt64 = 0) -> UniqueID {
        var timestampAndVersion = (rawTimestamp &<< 4).bigEndian
        withUnsafeMutableBytes(of: &timestampAndVersion) { timestamp_bytes in
            // Insert the 4 version bits in the top half of octet 6.
            timestamp_bytes[7] = timestamp_bytes[6] &<< 4 | timestamp_bytes[7] &>> 4
            timestamp_bytes[6] = 0x60 | timestamp_bytes[6] &>> 4
        }
        // Top 2 bits of octet 8 are the variant (0b10 = standard).
        let sequenceAndVariant = ((sequence & 0x3fff) | 0x8000).bigEndian
        let nodeBE = node.bigEndian
        
        var storage = UniqueID.zero.tuple
        withUnsafeMutableBytes(of: &storage) { bytes in
            withUnsafeBytes(of: timestampAndVersion) {
                bytes.baseAddress!.copyMemory(from: $0.baseAddress!, byteCount: 8)
            }
            withUnsafeBytes(of: sequenceAndVariant) {
                (bytes.baseAddress! + 8).copyMemory(from: $0.baseAddress!, byteCount: 2)
            }
            withUnsafeBytes(of: nodeBE) {
                (bytes.baseAddress! + 10).copyMemory(from: $0.baseAddress! + 2, byteCount: 6)
            }
        }
        return UniqueID(tuple: storage)
    }
    
    @inlinable
    static func timeOrdered(node: UInt64) -> UniqueID {
        let timestamp = Timestamp()
        
        let sequence = state.withLock { state in
            if state.timestamp >= timestamp {
                state.sequence &+= 1
            }
            state.timestamp = timestamp
            return state.sequence
        }
        
        let seconds = Int64(timestamp.components.seconds)
        let nanoseconds = Int64(timestamp.components.nanoseconds)
        let unix: UInt64 = (UInt64(bitPattern: seconds) &* 10_000_000) &+ (UInt64(bitPattern: nanoseconds) / 100)
        
        let rawTimestamp = unix_to_uuid_timestamp(unix: unix & 0x0FFF_FFFF_FFFF_FFFF)
        return timeOrdered(rawTimestamp: rawTimestamp, sequence: sequence, node: node)
    }
}

@inlinable
internal var timeOffset: UInt64 { 0x01b2_1dd2_1381_4000 }

@inlinable
internal func unix_to_uuid_timestamp(unix: UInt64) -> UInt64 {
    unix &+ timeOffset
}

@inlinable
internal func uuid_timestamp_to_unix(timestamp: UInt64) -> UInt64 {
    timestamp &- timeOffset
}
#endif
