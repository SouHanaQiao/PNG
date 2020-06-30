//
//  Protocols.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/9.
//  Copyright © 2019 葬花桥. All rights reserved.
//

public
protocol FixedLayoutColor:RandomAccessCollection, Hashable, CustomStringConvertible
    where Index == Int
{
    static
    var components:Int
    {
        get
    }
}

extension FixedLayoutColor
{
    @inlinable
    public
    var startIndex:Int
    {
        return 0
    }
    @inlinable
    public
    var endIndex:Int
    {
        return Self.components
    }
}

/// A fixed-width integer type which can be packed in groups of four within another
/// integer type. For example, four `UInt8`s may be packed into a single `UInt32`.
public
protocol FusedVector4Element:FixedWidthInteger & UnsignedInteger
{
    /// A fixed-width integer type which can hold four instances of `Self`.
    associatedtype FusedVector4:FixedWidthInteger & UnsignedInteger
}
extension UInt8:FusedVector4Element
{
    public
    typealias FusedVector4 = UInt32
}
extension UInt16:FusedVector4Element
{
    public
    typealias FusedVector4 = UInt64
}

/// An abstract data source. To provide a custom data source to the library, conform
/// your type to this protocol by implementing the `read(count:)` method.
public
protocol DataSource
{
    /// Read the specified number of bytes from this data source.
    /// - Parameters:
    ///     - count: The number of bytes to read.
    /// - Returns: An array of size `count`, if `count` bytes could be read, and
    ///     `nil` otherwise.
    mutating
    func read(count:Int) -> [UInt8]?
}

/// An abstract data destination. To specify a custom data destination for the library,
/// conform your type to this protocol by implementing the `write(_:)` method.
public
protocol DataDestination
{
    /// Write the given data buffer to this data destination.
    /// - Parameters:
    ///     - buffer: The data to write.
    /// - Returns: `()` on success, and `nil` otherwise.
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}
