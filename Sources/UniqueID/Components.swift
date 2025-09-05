import Timestamp

public protocol UniqueIDComponents {
    init?(_ uuid: UniqueID)
}

public extension UniqueID {
    typealias Components = UniqueIDComponents
    
    @inlinable
    func components<T: Components>(_: @autoclosure () -> T) -> T? {
        T(self)
    }
}

extension UniqueID.Components where Self == UniqueID.TimeOrdered {
    public static var timeOrdered: Self { preconditionFailure("Not intended to be called") }
}

extension UniqueID {
    public struct TimeOrdered: UniqueID.Components {
        
        @usableFromInline
        internal let uuid: UniqueID
        
        @inlinable
        public init?(_ uuid: UniqueID) {
            guard uuid.version == 6 else { return nil }
            self.uuid = uuid
        }
        
        @inlinable
        internal var rawTimestamp: UInt64 {
            var timestamp: UInt64 = 0
            withUnsafeMutableBytes(of: &timestamp) { timestamp_bytes in
                withUnsafeBytes(of: uuid.tuple) { uuidBytes in
                    timestamp_bytes.copyMemory(from: UnsafeRawBufferPointer(start: uuidBytes.baseAddress, count: 8))
                }
                // Remove the UUID version bits.
                timestamp_bytes[6] = timestamp_bytes[6] &<< 4 | timestamp_bytes[7] &>> 4
                timestamp_bytes[7] = timestamp_bytes[7] &<< 4
            }
            return (timestamp.bigEndian &>> 4)  // Widen to 64 bits
        }
        
        @inlinable
        public var timestamp: Timestamp {
            .nanoseconds(uuid_timestamp_to_unix(timestamp: rawTimestamp) * 100)
        }
        
        @inlinable
        public var sequence: UInt16 {
            var clk_seq: UInt16 = 0
            withUnsafeMutableBytes(of: &clk_seq) { clk_seq_bytes in
                withUnsafeBytes(of: uuid.tuple) { uuid_bytes in
                    clk_seq_bytes.copyMemory(from: UnsafeRawBufferPointer(start: uuid_bytes.baseAddress! + 8, count: 2))
                }
            }
            return (clk_seq.bigEndian & 0x3FFF)  // Remove the variant bits.
        }
        
        @inlinable
        public var node: UInt {
            var node: UInt = 0
            withUnsafeMutableBytes(of: &node) { nodeID_bytes in
                withUnsafeBytes(of: uuid.tuple) { uuidBytes in
                    nodeID_bytes.baseAddress!.advanced(by: 2).copyMemory(from: uuidBytes.baseAddress! + 10, byteCount: 6)
                }
            }
            return node.bigEndian
        }
    }
}
