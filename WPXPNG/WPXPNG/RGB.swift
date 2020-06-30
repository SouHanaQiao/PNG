//
//  RGB.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/9.
//  Copyright © 2019 葬花桥. All rights reserved.
//

/// A four-component color value, with components stored in the RGBA color model.
/// This structure has fixed layout, with the red component first, then green,
/// then blue, then alpha. Buffers containing instances of this type may be
/// safely reinterpreted as flat buffers containing interleaved components.
@_fixed_layout
public
struct RGBA<Component>:Hashable where Component:FixedWidthInteger & UnsignedInteger
{
    /// The red component of this color.
    public
    var r:Component
    /// The green component of this color.
    public
    var g:Component
    /// The blue component of this color.
    public
    var b:Component
    /// The alpha component of this color.
    public
    var a:Component
    
    
    /// Creates an opaque grayscale color with all color components set to the given
    /// value sample, and the alpha component set to `Component.max`.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - value: The value to initialize all color components to.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    init(_ value:Component)
    {
        self.init(value, value, value, Component.max)
    }
    
    /// Creates a grayscale color with all color components set to the given
    /// value sample, and the alpha component set to the given alpha sample.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - value: The value to initialize all color components to.
    ///     - alpha: The value to initialize the alpha component to.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    init(_ value:Component, _ alpha:Component)
    {
        self.init(value, value, value, alpha)
    }
    
    /// Creates an opaque color with the given color samples, and the alpha
    /// component set to `Component.max`.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - red: The value to initialize the red component to.
    ///     - green: The value to initialize the green component to.
    ///     - blue: The value to initialize the blue component to.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    init(_ red:Component, _ green:Component, _ blue:Component)
    {
        self.init(red, green, blue, Component.max)
    }
    
    /// Creates an opaque color with the given color and alpha samples.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - red: The value to initialize the red component to.
    ///     - green: The value to initialize the green component to.
    ///     - blue: The value to initialize the blue component to.
    ///     - alpha: The value to initialize the alpha component to.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    init(_ red:Component, _ green:Component, _ blue:Component, _ alpha:Component)
    {
        self.r = red
        self.g = green
        self.b = blue
        self.a = alpha
    }
    
    init(_ va:VA<Component>)
    {
        self.init(va.v, va.a)
    }
    
    /// The color obtained by premultiplying the red, green, and blue components
    /// of this color with its alpha component. The resulting component values
    /// are accurate to within 1 `Component` unit.
    ///
    /// *Inlinable*.
    @inlinable
    public
    var premultiplied:RGBA<Component>
    {
        return .init(   RGBA.premultiply(color: self.r, alpha: self.a),
                        RGBA.premultiply(color: self.g, alpha: self.a),
                        RGBA.premultiply(color: self.b, alpha: self.a),
                        self.a)
    }
    
    @usableFromInline
    static
        func premultiply<Component>(color:Component, alpha:Component) -> Component
        where Component: FixedWidthInteger & UnsignedInteger
    {
        // an overflow-safe way of computing p = (c * (a + 1)) >> p.bitWidth
        let (high, low):(Component, Component.Magnitude) = color.multipliedFullWidth(by: alpha)
        // divide by 255 using this one neat trick!1!!!
        // value /. 255 == (value + 128 + (value >> 8)) >> 8
        let carries:(Bool, Bool),
        partialValue:Component.Magnitude
        (partialValue, carries.0) = low.addingReportingOverflow(high.magnitude)
        carries.1  = partialValue.addingReportingOverflow(Component.Magnitude.max >> 1 + 1).overflow
        return high + (carries.0 ? 1 : 0) + (carries.1 ? 1 : 0)
    }
    
    /// The red, and alpha components of this color, stored as a grayscale-alpha
    /// color.
    ///
    /// *Inlinable*.
    @inlinable
    public
    var va:VA<Component>
    {
        return .init(self.r, self.a)
    }
    
    /// Returns a copy of this color with the alpha component set to the given sample.
    /// - Parameters:
    ///     - a: An alpha sample.
    /// - Returns: This color with the alpha component set to the given sample.
    func withAlpha(_ a:Component) -> RGBA<Component>
    {
        return .init(self.r, self.g, self.b, a)
    }
    
    /// Returns a boolean value indicating whether the color components of this
    /// color are equal to the color components of the given color, ignoring
    /// the alpha components.
    /// - Parameters:
    ///     - other: Another color.
    /// - Returns: `true` if the red, green, and blue components of this color
    ///     and `other` are equal, `false` otherwise.
    func equals(opaque other:RGBA<Component>) -> Bool
    {
        return self.r == other.r && self.g == other.g && self.b == other.b
    }
}

/// A two-component color value, with components stored in the grayscale-alpha
/// color model. This structure has fixed layout, with the value component first,
/// then alpha. Buffers containing instances of this type may be safely reinterpreted
/// as flat buffers containing interleaved components.
@_fixed_layout
public
struct VA<Component>:Hashable where Component:FixedWidthInteger & UnsignedInteger
{
    /// The value component of this color.
    public
    var v:Component
    /// The alpha component of this color.
    public
    var a:Component
    
    /// Creates an opaque grayscale color with the value component set to the
    /// given value sample, and the alpha component set to `Component.max`.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - value: The value to initialize the value component to.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    init(_ value:Component)
    {
        self.init(value, Component.max)
    }
    
    /// Creates a grayscale color with the value component set to the given
    /// value sample, and the alpha component set to the given alpha sample.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - value: The value to initialize the value component to.
    ///     - alpha: The value to initialize the alpha component to.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    init(_ value:Component, _ alpha:Component)
    {
        self.v = value
        self.a = alpha
    }
    
    /// Returns a copy of this color with the alpha component set to the given sample.
    /// - Parameters:
    ///     - a: An alpha sample.
    /// - Returns: This color with the alpha component set to the given sample.
    func withAlpha(_ a:Component) -> VA<Component>
    {
        return .init(self.v, a)
    }
    
    /// The color obtained by premultiplying the value component of this color
    /// with its alpha component. The resulting component values are accurate
    /// to within 1 `Component` unit.
    ///
    /// *Inlinable*.
    @inlinable
    public
    var premultiplied:VA<Component>
    {
        return .init(VA.premultiply(color: self.v, alpha: self.a), self.a)
    }
    
    @usableFromInline
    static
        func premultiply<Component>(color:Component, alpha:Component) -> Component
        where Component:FixedWidthInteger & UnsignedInteger
    {
        // an overflow-safe way of computing p = (c * (a + 1)) >> p.bitWidth
        let (high, low):(Component, Component.Magnitude) = color.multipliedFullWidth(by: alpha)
        // divide by 255 using this one neat trick!1!!!
        // value /. 255 == (value + 128 + (value >> 8)) >> 8
        let carries:(Bool, Bool),
        partialValue:Component.Magnitude
        (partialValue, carries.0) = low.addingReportingOverflow(high.magnitude)
        carries.1  = partialValue.addingReportingOverflow(Component.Magnitude.max >> 1 + 1).overflow
        return high + (carries.0 ? 1 : 0) + (carries.1 ? 1 : 0)
    }
}

extension RGBA: FixedLayoutColor
{
    /// A textual representation of this color.
    public
    var description:String
    {
        return "(\(self.r), \(self.g), \(self.b), \(self.a))"
    }
    
    @inlinable
    public static
    var components:Int
    {
        return 4
    }
    
    @inlinable
    public
    subscript(index:Int) -> Component
    {
        switch index
        {
        case 0:
            return self.r
        case 1:
            return self.g
        case 2:
            return self.b
        case 3:
            return self.a
        default:
            fatalError("(RGBA) index \(index) out of range")
        }
    }
}

extension RGBA where Component:FusedVector4Element
{
    /// The components of this pixel value packed into a single unsigned integer in
    /// ARGB order, with the alpha component in the high bits.
    ///
    /// *Inlinable*.
    @inlinable
    public
    var argb: Component.FusedVector4
    {
        let a:Math<Component.FusedVector4>.V4 =
            Math.cast((self.a, self.r, self.g, self.b), as: Component.FusedVector4.self)
        
        let x:Math<Component.FusedVector4>.V4
        
        x.0 = a.0 << (Component.bitWidth << 1 | Component.bitWidth)
        x.1 = a.1 << (Component.bitWidth << 1)
        x.2 = a.2 << (Component.bitWidth)
        x.3 = a.3
        
        return x.0 | x.1 | x.2 | x.3
    }
}

public struct Bitmap {
    public var size: (width: Int, height: Int)
    public var pixels: [RGBA<UInt8>]
    
    public init(size: (width: Int, height: Int), pixels: [RGBA<UInt8>]) {
        self.size = size
        self.pixels = pixels
    }
}

extension WPX.PNG {
    public var bitmap: Bitmap {
        return Bitmap(size: size, pixels: rgba(of: UInt8.self))
    }
}

#if os(macOS)

#elseif os(iOS)
import UIKit
public extension Bitmap {
    var image: UIImage? {
        
        let component = 4
        
        let pointer = pixels.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: pixels.count * component) {
                UnsafeMutablePointer<UInt8>(mutating: $0)
            }
        }

        let bitsPerComponent = UInt8.bitWidth
        let bytesPerRow = component * size.width
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        if let context = CGContext(data: pointer, width: size.width, height: size.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpaceRef, bitmapInfo: bitmapInfo.rawValue) {
            if let imageRefExtended = context.makeImage() {
                return UIImage(cgImage: imageRefExtended)
            }
        }
        
        return nil
    }
}
#endif

