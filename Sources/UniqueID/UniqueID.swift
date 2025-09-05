public struct UniqueID: Sendable {
    public typealias Bytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )
    
    public let tuple: Bytes
    
    @inlinable
    public init(tuple: Bytes) {
        self.tuple = tuple
    }
}

extension UniqueID: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        self.init(internal: description)
    }
    
    @inlinable
    public init?<S: StringProtocol>(internal string: S) {
        let parsed = string.utf8.withContiguousStorageIfAvailable { UniqueID(utf8: $0) }
        guard let parsed = parsed, let parsed = parsed else {
            return nil
        }
        self = parsed
    }
}

extension UniqueID: CustomStringConvertible {
    @inlinable
    public var description: String {
        serialized()
    }
}

extension UniqueID: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = UniqueID(internal: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid UUID string")
        }
        self = value
    }
    
    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension UniqueID: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: tuple) { hasher.combine(bytes: $0) }
    }
}

extension UniqueID: Equatable {
    @inlinable
    public static func == (lhs: UniqueID, rhs: UniqueID) -> Bool {
        withUnsafeBytes(of: lhs.tuple) { lhsBytes in
            withUnsafeBytes(of: rhs.tuple) { rhsBytes in
                lhsBytes.elementsEqual(rhsBytes)
            }
        }
    }
}

extension UniqueID: Comparable {
    @inlinable
    public static func < (lhs: UniqueID, rhs: UniqueID) -> Bool {
        withUnsafeBytes(of: lhs.tuple) { lhsBytes in
            withUnsafeBytes(of: rhs.tuple) { rhsBytes in
                lhsBytes.lexicographicallyPrecedes(rhsBytes)
            }
        }
    }
}

public extension UniqueID {
    @inlinable 
    static var zero: UniqueID {
        UniqueID(tuple: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    }
    
    @inlinable 
    var version: Int? {
        guard (tuple.8 &>> 6) == 0b00000010 else { return nil }
        return Int((tuple.6 & 0b1111_0000) &>> 4)
    }
}

public extension UniqueID {
    @inlinable
    init?<Bytes: Sequence>(bytes: Bytes) where Bytes.Element == UInt8 {
        var tuple = UniqueID.zero.tuple
        let copied = withUnsafeMutableBytes(of: &tuple) { tuple in
            UnsafeMutableBufferPointer(
                start: tuple.baseAddress.unsafelyUnwrapped.assumingMemoryBound(to: UInt8.self),
                count: 16
            ).initialize(from: bytes).1
        }
        guard copied == 16 else { return nil }
        self.init(tuple: tuple)
    }
    
    @inlinable
    init() {
        self = .random()
    }
    
    var bytes: [UInt8] {
        withUnsafePointer(to: tuple, {
            Array(UnsafeBufferPointer(start: UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self), count: 16))
        })
    }
}
