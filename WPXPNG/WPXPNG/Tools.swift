//
//  Tools.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/9.
//  Copyright © 2019 葬花桥. All rights reserved.
//

struct Bitfield<Storage> where Storage:FixedWidthInteger & UnsignedInteger
{
    private
    var storage:Storage
    
    init()
    {
        self.storage = .init()
    }
    
    subscript(index:Int) -> Bool
    {
        get
        {
            return self.storage & (1 << index) != 0
        }
        
        set(value)
        {
            if value
            {
                self.storage |=  (1 &<< index)
            }
            else
            {
                self.storage &= ~(1 &<< index)
            }
        }
    }
    
    mutating
    func testAndSet(_ index:Int) -> Bool
    {
        defer
        {
            self[index] = true
        }
        
        return self[index]
    }
}

extension Array {
    init(
        unsafeUninitializedCapacity: Int,
        initializingWith initializer: (
        _ buffer: inout UnsafeMutableBufferPointer<Element>,
        _ initializedCount: inout Int
        ) throws -> Void
        ) rethrows {
        self = []
        try self.withUnsafeMutableBufferPointerToStorage(capacity: unsafeUninitializedCapacity, initializer)
    }
    
    mutating func withUnsafeMutableBufferPointerToStorage<Result>(
        capacity: Int,
        _ body: (
        _ buffer: inout UnsafeMutableBufferPointer<Element>,
        _ initializedCount: inout Int
        ) throws -> Result
        ) rethrows -> Result {
        var buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: capacity)
        let _ = buffer.initialize(from: self)
        var initializedCount = self.count
        defer {
            buffer.baseAddress?.deinitialize(count: initializedCount)
            buffer.deallocate()
        }
        
        let result = try body(&buffer, &initializedCount)
        self = Array.init(buffer[..<initializedCount])
        self.reserveCapacity(capacity)
        return result
    }
}

extension Array where Element == UInt8
{
    /// Loads a misaligned big-endian integer value from the given byte offset
    /// and casts it to a desired format.
    /// - Parameters:
    ///     - bigEndian: The size and type to interpret the data to load as.
    ///     - type: The type to cast the read integer value to.
    ///     - byte: The byte offset to load the big-endian integer from.
    /// - Returns: The read integer value, cast to `U`.
    internal
    func load<T, U>(bigEndian:T.Type, as type:U.Type, at byte:Int) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(bigEndian: T.self, as: U.self)
    }
    
    /// Decomposes the given integer value into its constituent bytes, in big-endian order.
    /// - Parameters:
    ///     - value: The integer value to decompose.
    ///     - type: The big-endian format `T` to store the given `value` as. The given
    ///             `value` is truncated to fit in a `T`.
    /// - Returns: An array containing the bytes of the given `value`, in big-endian order.
    internal static
        func store<U, T>(_ value:U, asBigEndian type:T.Type) -> [UInt8]
        where U:BinaryInteger, T:FixedWidthInteger
    {
        return .init(unsafeUninitializedCapacity: MemoryLayout<T>.size)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
            
            let bigEndian:T = T.init(truncatingIfNeeded: value).bigEndian,
            destination:UnsafeMutableRawBufferPointer = .init(buffer)
            Swift.withUnsafeBytes(of: bigEndian)
            {
                destination.copyMemory(from: $0)
                count = $0.count
            }
        }
    }
    
    internal mutating
    func append(bigEndian:UInt16)
    {
        self.append(.init(truncatingIfNeeded: bigEndian >> 8))
        self.append(.init(truncatingIfNeeded: bigEndian     ))
    }
}

extension ArraySlice where Element == UInt8
{
    /// Loads this array slice as a misaligned big-endian integer value,
    /// and casts it to a desired format.
    /// - Parameters:
    ///     - bigEndian: The size and type to interpret this array slice as.
    ///     - type: The type to cast the read integer value to.
    /// - Returns: The read integer value, cast to `U`.
    internal
    func load<T, U>(bigEndian:T.Type, as type:U.Type) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer
            {
                (buffer:UnsafeBufferPointer<UInt8>) in
                
                assert(buffer.count >= MemoryLayout<T>.size,
                       "attempt to load \(T.self) from slice of size \(buffer.count)")
                
                var storage:T = .init()
                let value:T   = withUnsafeMutablePointer(to: &storage)
                {
                    $0.deinitialize(count: 1)
                    
                    let source:UnsafeRawPointer     = .init(buffer.baseAddress!),
                    raw:UnsafeMutableRawPointer = .init($0)
                    
                    raw.copyMemory(from: source, byteCount: MemoryLayout<T>.size)
                    
                    return raw.load(as: T.self)
                }
                
                return U(T(bigEndian: value))
        }
    }
}


// ...you win this round, swift evolution
extension BinaryInteger
{
    @inlinable
    func isMultiple(of other:Self) -> Bool
    {
        // Nothing but zero is a multiple of zero.
        if other == 0
        {
            return self == 0
        }
        
        // Special case to avoid overflow on .min / -1 for signed types.
        if Self.isSigned && other == -1
        {
            return true
        }
        
        // Having handled those special cases, this is safe.
        return self % other == 0
    }
}

// goodies from the future (5.0)
extension Sequence {
    /// Returns the number of elements in the sequence that satisfy the given
    /// predicate.
    ///
    /// You can use this method to count the number of elements that pass a test.
    /// For example, this code finds the number of names that are fewer than
    /// five characters long:
    ///
    ///     let names = ["Jacqueline", "Ian", "Amy", "Juan", "Soroush", "Tiffany"]
    ///     let shortNameCount = names.count(where: { $0.count < 5 })
    ///     // shortNameCount == 3
    ///
    /// To find the number of times a specific element appears in the sequence,
    /// use the equal-to operator (`==`) in the closure to test for a match.
    ///
    ///     let birds = ["duck", "duck", "duck", "duck", "goose"]
    ///     let duckCount = birds.count(where: { $0 == "duck" })
    ///     // duckCount == 4
    ///
    /// The sequence must be finite.
    ///
    /// - Parameter predicate: A closure that takes each element of the sequence
    ///   as its argument and returns a Boolean value indicating whether
    ///   the element should be included in the count.
    /// - Returns: The number of elements in the sequence that satisfy the given
    ///   predicate.
    @inlinable
    func count(
        where predicate: (Element) throws -> Bool
        ) rethrows -> Int {
        var count = 0
        for e in self {
            if try predicate(e) {
                count += 1
            }
        }
        return count
    }
}
