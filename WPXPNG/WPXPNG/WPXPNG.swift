//
//  WPXPNG.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/9.
//  Copyright © 2019 葬花桥. All rights reserved.
//

import zlib
import WPXPNGC

public enum WPX {
    
    public struct PNG {
        
        /// The shape of an image stored in a two-dimensional array.
        struct Shape
        {
            let pitch:Int,
            size:(x:Int, y:Int)
            
            var byteCount:Int
            {
                return self.pitch * self.size.y
            }
        }
        
        /// A pixel format used to encode the color values of a PNG.
        ///
        /// Pixel formats consist of a color format, and a color depth.
        ///
        /// Color formats can have multiple components, one for each independent
        /// dimension pixel values encoded in this format have. A grayscale format,
        /// for example, has one component (value), while an RGBA format has four
        /// (red, green, blue, alpha).
        ///
        /// Components are separate from channels, which are the independent values
        /// needed to *encode*a pixel value in a PNG image. An indexed pixel format,
        /// for example, has only one channel — a scalar index into a palette table —
        /// but has three components, as the entries in the palette table encode
        /// red, green, and blue components.
        ///
        /// Color depth refers to the number of bits of precision used to encode
        /// each channel.
        ///
        /// Not all combinations of color formats and color depths are allowed.
        ///
        /// | *depth* |  indexed   |   grayscale   | grayscale-alpha |   RGB   |   RGBA   |
        /// | ------- | ---------- | ------------- | --------------- | ------- | -------- |
        /// |    1    | `indexed1` | `v1`          |
        /// |    2    | `indexed2` | `v2`          |
        /// |    4    | `indexed4` | `v4`          |
        /// |    8    | `indexed8` | `v8`          | `va8`           | `rgb8`  | `rgba8`  |
        /// |    16   |            | `v16`         | `va16`          | `rgb16` | `rgba16` |
        public
        enum Format
        {
            case    v1,
            v2,
            v4,
            v8,
            v16,
            rgb8(_ palette:[RGBA<UInt8>]?),
            rgb16(_ palette:[RGBA<UInt8>]?),
            indexed1(_ palette:[RGBA<UInt8>]),
            indexed2(_ palette:[RGBA<UInt8>]),
            indexed4(_ palette:[RGBA<UInt8>]),
            indexed8(_ palette:[RGBA<UInt8>]),
            va8,
            va16,
            rgba8(_ palette:[RGBA<UInt8>]?),
            rgba16(_ palette:[RGBA<UInt8>]?)
            
            public
            enum Code:UInt16
            {
                case    v1          = 0x01_00,
                v2          = 0x02_00,
                v4          = 0x04_00,
                v8          = 0x08_00,
                v16         = 0x10_00,
                rgb8        = 0x08_02,
                rgb16       = 0x10_02,
                indexed1    = 0x01_03,
                indexed2    = 0x02_03,
                indexed4    = 0x04_03,
                indexed8    = 0x08_03,
                va8         = 0x08_04,
                va16        = 0x10_04,
                rgba8       = 0x08_06,
                rgba16      = 0x10_06
                
                /// The bit depth of each channel of this pixel format.
                @inlinable
                public
                var depth:Int
                {
                    return .init(self.rawValue >> 8)
                }
                
                /// A boolean value indicating if this pixel format has indexed color.
                ///
                /// `true` if `self` is `indexed1`, `indexed2`, `indexed4`, or `indexed8`.
                /// `false` otherwise.
                @inlinable
                public
                var isIndexed:Bool
                {
                    return self.rawValue & 1 != 0
                }
                
                /// A boolean value indicating if this pixel format has at least three
                /// color components.
                ///
                /// `true` if `self` is `indexed1`, `indexed2`, `indexed4`, `indexed8`,
                /// `rgb8`, `rgb16`, `rgba8`, or `rgba16`. `false` otherwise.
                @inlinable
                public
                var hasColor:Bool
                {
                    return self.rawValue & 2 != 0
                }
                
                /// A boolean value indicating if this pixel format has an alpha channel.
                ///
                /// `true` if `self` is `va8`, `va16`, `rgba8`, or
                /// `rgba16`. `false` otherwise.
                @inlinable
                public
                var hasAlpha:Bool
                {
                    return self.rawValue & 4 != 0
                }
                
                /// The number of channels encoded by this pixel format.
                @inlinable
                public
                var channels:Int
                {
                    switch self
                    {
                    case .v1, .v2, .v4, .v8, .v16,
                         .indexed1, .indexed2, .indexed4, .indexed8:
                        return 1
                    case .va8, .va16:
                        return 2
                    case .rgb8, .rgb16:
                        return 3
                    case .rgba8, .rgba16:
                        return 4
                    }
                }
                
                /// The total number of bits needed to encode all channels of this pixel
                /// format.
                @inlinable
                var volume:Int
                {
                    return self.depth * self.channels
                }
                
                /// The number of components represented by this pixel format.
                @inlinable
                public
                var components:Int
                {
                    switch self
                    {
                    case .v1, .v2, .v4, .v8, .v16:
                        return 1
                    case .va8, .va16:
                        return 2
                    case .rgb8, .rgb16:
                        return 3
                    case .rgba8, .rgba16,
                         .indexed1, .indexed2, .indexed4, .indexed8:
                        return 4
                    }
                }
                
                /// Returns the shape of a buffer just large enough to contain an image
                /// of the given size, stored in this color format.
                func shape(from size:Math<Int>.V2) -> Shape
                {
                    let scanlineBitCount:Int = size.x * self.channels * self.depth
                    // ceil(scanlineBitCount / 8)
                    let pitch:Int = scanlineBitCount >> 3 + (scanlineBitCount & 7 == 0 ? 0 : 1)
                    return .init(pitch: pitch, size: size)
                }
            }
            
            public init(code: Code, palette: [RGBA<UInt8>]? = nil) throws  {
                switch code {
                case .v1:
                    self = .v1
                case .v2:
                    self = .v2
                case .v4:
                    self = .v4
                case .v8:
                    self = .v8
                case .v16:
                    self = .v16
                case .rgb8:
                    self = .rgb8(palette)
                case .rgb16:
                    self = .rgb16(palette)
                case .indexed1:
                    guard let palette = palette else {
                        throw DecodingError.missingChunk(.palette)
                    }
                    self = .indexed1(palette)
                case .indexed2:
                    guard let palette = palette else {
                        throw DecodingError.missingChunk(.palette)
                    }
                    self = .indexed2(palette)
                case .indexed4:
                    guard let palette = palette else {
                        throw DecodingError.missingChunk(.palette)
                    }
                    self = .indexed4(palette)
                case .indexed8:
                    guard let palette = palette else {
                        throw DecodingError.missingChunk(.palette)
                    }
                    self = .indexed8(palette)
                case .va8:
                    self = .va8
                case .va16:
                    self = .va16
                case .rgba8:
                    self = .rgba8(palette)
                case .rgba16:
                    self = .rgba16(palette)
                }
            }
            
            @inlinable
            public
            var code:Code
            {
                switch self
                {
                case .v1:
                    return .v1
                case .v2:
                    return .v2
                case .v4:
                    return .v4
                case .v8:
                    return .v8
                case .v16:
                    return .v16
                case .rgb8:
                    return .rgb8
                case .rgb16:
                    return .rgb16
                case .indexed1:
                    return .indexed1
                case .indexed2:
                    return .indexed2
                case .indexed4:
                    return .indexed4
                case .indexed8:
                    return .indexed8
                case .va8:
                    return .va8
                case .va16:
                    return .va16
                case .rgba8:
                    return .rgba8
                case .rgba16:
                    return .rgba16
                }
            }
            
            /// The palette associated with this color format, if applicable.
            public
            var palette:[RGBA<UInt8>]?
            {
                switch self
                {
                case    let .indexed1(palette),
                        let .indexed2(palette),
                        let .indexed4(palette),
                        let .indexed8(palette):
                    return palette
                    
                case    let .rgb8(option),
                        let .rgb16(option),
                        let .rgba8(option),
                        let .rgba16(option):
                    return option
                default:
                    return nil
                }
            }
        }
        
        /// An interlacing algorithm used to arrange the stored pixels in a PNG image.
        public enum Interlacing
        {
            /// A sub-image of a PNG image using the Adam7 interlacing algorithm.
            public struct SubImage
            {
                /// The shape of a two-dimensional array containing this sub-image.
                let shape: Shape
                /// Two sequences of two-dimensional coordinates representing the
                /// logical positions of each pixel in this sub-image, when deinterlaced
                /// with its other sub-images.
                let strider: Math<StrideTo<Int>>.V2
            }
            
            /// No interlacing.
            case none
            /// [Adam7](https://en.wikipedia.org/wiki/Adam7_algorithm) interlacing.
            case adam7([SubImage])
            
            /// Returns the index ranges containing each Adam7 sub-image when all
            /// sub-images are packed back-to-back in a single buffer, starting
            /// with the smallest sub-image.
            static
                func computeAdam7Ranges(_ subImages:[SubImage]) -> [Range<Int>]
            {
                var accumulator:Int = 0
                return subImages.map
                    {
                        let upper:Int = accumulator + $0.shape.byteCount
                        defer
                        {
                            accumulator = upper
                        }
                        
                        return accumulator ..< upper
                }
            }
        }
        
        /// The sequence of scanline pitches forming the data buffer of a PNG image.
        struct Pitches: Sequence, IteratorProtocol
        {
            private
            let footprints: [(pitch:Int, height:Int)]
            
            private
            var f: Int         = 0
            
            public var scanlines: Int = 0
            
            public var totalScanlines: Int {
                return footprints.reduce(0) {
                    $0 + $1.height
                }
            }
            
            public var byteCount: Int {
                return footprints.reduce(0) {
                    $0 + $1.pitch*$1.height
                }
            }
            
            /// Creates the pitch sequence for an Adam7 interlaced PNG with the
            /// given sub-images.
            ///
            /// - Parameters:
            ///     - subImages: The sub-images of an interlaced image.
            init(subImages:[Interlacing.SubImage])
            {
                self.footprints = subImages.map
                    {
                        ($0.shape.pitch, $0.shape.size.y)
                }
            }
            
            /// Creates the pitch sequence for a non-interlaced PNG with the given
            /// shape.
            ///
            /// - Parameters:
            ///     - shape: The shape of a non-interlaced image.
            init(shape: Shape)
            {
                self.footprints = [(shape.pitch, shape.size.y)]
            }
            
            /// Returns the pitch of the next scanline, if it is different from
            /// the pitch of the previous scanline.
            ///
            /// - Returns: The pitch of the next scanline, if it is different from
            ///     that of the previous scanline, `nil` in the inner optional if
            ///     it is the same as that of the previous scanline, and `nil` in
            ///     the outer optional if there should be no more scanlines left
            ///     in the image.
            mutating
            func next() -> Int??
            {
                let f:Int = self.f
                while self.scanlines == 0
                {
                    guard self.f < self.footprints.count
                        else
                    {
                        return nil
                    }
                    
                    if self.footprints[self.f].pitch == 0
                    {
                        self.scanlines = 0
                    }
                    else
                    {
                        self.scanlines = self.footprints[self.f].height
                    }
                    
                    self.f += 1
                }
                
                self.scanlines -= 1
                return self.f != f ? self.footprints[self.f - 1].pitch : .some(nil)
            }
        }
        
        public struct Header {
            /// 图像尺寸，以像素为单位 PNG image size
            public let size: (width: Int, height: Int)
            /// high 8 bit: bit depth, low 8 bit: color type
            public let code: Format.Code
            /// 压缩方法只有0：LZ77派生算法
            public let compressionMethod: Int = 0
            /// 滤波器方法只有0
            public let filterMethod: Int = 0
            /// 隔行扫描方法 0：非隔行扫描 1： Adam7(由Adam M. Costello开发的7遍隔行扫描方法)
            public private(set) var interlaceMethod: Interlacing
            
            /// Decodes the data of an IHDR chunk as a `Properties` record.
            ///
            /// - Parameters:
            ///     - data: IHDR chunk data.
            /// - Returns: A `Properties` object containing the information encoded by
            ///     the given IHDR chunk.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If any of the IHDR chunk fields contain
            ///         an invalid value.
            public static
                func decodeIHDR(_ data:[UInt8]) throws -> Header
            {
                guard data.count == 13
                    else
                {
                    throw DecodingError.invalidChunk(message: "png header length is \(data.count), expected 13")
                }
                
                let colorcode:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 8)
                guard let code:Format.Code = Format.Code.init(rawValue: colorcode)
                    else
                {
                    throw DecodingError.invalidChunk(message: "color format bytes have invalid values (\(data[8]), \(data[9]))")
                }
                
                // validate other fields
                guard data[10] == 0
                    else
                {
                    throw DecodingError.invalidChunk(message: "compression byte has value \(data[10]), expected 0")
                }
                guard data[11] == 0
                    else
                {
                    throw DecodingError.invalidChunk(message: "filter byte has value \(data[11]), expected 0")
                }
                
                let width:Int  = data.load(bigEndian: UInt32.self, as: Int.self, at: 0),
                height:Int = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
                
                let interlaced: Interlacing
                let size: (x:Int, y:Int) = (x: width, y: height)
                switch data[12]
                {
                case 0:
                    interlaced = .none
                case 1:
                    // calculate size of interlaced subimages
                    // 0: (w + 7) >> 3 , (h + 7) >> 3
                    // 1: (w + 3) >> 3 , (h + 7) >> 3
                    // 2: (w + 3) >> 2 , (h + 3) >> 3
                    // 3: (w + 1) >> 2 , (h + 3) >> 2
                    // 4: (w + 1) >> 1 , (h + 1) >> 2
                    // 5: (w) >> 1     , (h + 1) >> 1
                    // 6: (w)          , (h) >> 1
                    let sizes:[Math<Int>.V2] =
                        [
                            ((size.x + 7) >> 3, (size.y + 7) >> 3),
                            ((size.x + 3) >> 3, (size.y + 7) >> 3),
                            ((size.x + 3) >> 2, (size.y + 3) >> 3),
                            ((size.x + 1) >> 2, (size.y + 3) >> 2),
                            ((size.x + 1) >> 1, (size.y + 1) >> 2),
                            ( size.x      >> 1, (size.y + 1) >> 1),
                            ( size.x      >> 0,  size.y      >> 1)
                    ]
                    
                    let striders:[Math<StrideTo<Int>>.V2] =
                        [
                            (stride(from: 0, to: size.x, by: 8), stride(from: 0, to: size.y, by: 8)),
                            (stride(from: 4, to: size.x, by: 8), stride(from: 0, to: size.y, by: 8)),
                            (stride(from: 0, to: size.x, by: 4), stride(from: 4, to: size.y, by: 8)),
                            (stride(from: 2, to: size.x, by: 4), stride(from: 0, to: size.y, by: 4)),
                            (stride(from: 0, to: size.x, by: 2), stride(from: 2, to: size.y, by: 4)),
                            (stride(from: 1, to: size.x, by: 2), stride(from: 0, to: size.y, by: 2)),
                            (stride(from: 0, to: size.x, by: 1), stride(from: 1, to: size.y, by: 2))
                    ]
                    
                    
                    let subImages:[Interlacing.SubImage] = zip(sizes, striders).map
                    {
                        (size:Math<Int>.V2, strider:Math<StrideTo<Int>>.V2) in
                        
                        
                        return Interlacing.SubImage.init(shape: code.shape(from: size), strider: strider)
                    }
                    
                    interlaced = .adam7(subImages)
                default:
                    throw DecodingError.invalidChunk(message: "interlacing byte has invalid value \(data[12])")
                }
                
                
                
                return .init(size: (width, height), code: code, interlaceMethod: interlaced)
            }
            
            /// Encodes the header fields of this `Properties` record as the chunk data
            /// of an IHDR chunk.
            ///
            /// - Returns: An array containing IHDR chunk data. The chunk header, length,
            ///     and crc32 tail are not included.
            public
            func encodeIHDR() -> [UInt8]
            {
                var interlaced: UInt8 = 0
                switch interlaceMethod {
                case .none:
                    interlaced = 0
                case .adam7:
                    interlaced = 1
                }
                
                let header: [UInt8] =
                    [UInt8].store(self.size.width,         asBigEndian: UInt32.self) +
                        [UInt8].store(self.size.height,         asBigEndian: UInt32.self) +
                        [UInt8].store(self.code.rawValue, asBigEndian: UInt16.self) +
                        [0, 0, interlaced]
                
                return header
            }
            
            /// Decodes the data of a PLTE chunk, validates, and returns it as an
            /// array of `PNG.RGBA<UInt8>` entries.
            ///
            /// - Parameters:
            ///     - data: PLTE chunk data. Must not contain more entries than this
            ///         PNG’s color depth can uniquely encode.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given palette data does not contain
            ///         a whole number of palette entries, or if it contains more than
            ///         `1 << format.depth` entries
            ///     - DecodingError.unexpectedChunk: If this PNG does not have
            ///         a three-color format.
            public
            func decodePLTE(_ data: [UInt8]) throws -> [RGBA<UInt8>]
            {
                guard self.code.hasColor
                    else
                {
                    throw DecodingError.unexpectedChunk(.core(.palette))
                }
                
                guard data.count.isMultiple(of: 3)
                    else
                {
                    throw DecodingError.invalidChunk(message: "palette does not contain a whole number of entries (\(data.count) bytes)")
                }
                
                // check number of palette entries
                let maxEntries:Int = 1 << self.code.depth
                guard data.count <= maxEntries * 3
                    else
                {
                    throw DecodingError.invalidChunk(message: "palette contains too many entries (found \(data.count / 3), expected\(maxEntries))")
                }
                
                return stride(from: data.startIndex, to: data.endIndex, by: 3).map
                    {
                        let r:UInt8 = data[$0    ],
                        g:UInt8 = data[$0 + 1],
                        b:UInt8 = data[$0 + 2]
                        return .init(r, g, b)
                }
            }
            
            /// Decodes the data of a tRNS chunk, validates, and modifies the given
            /// palette table.
            ///
            /// This method should only be called if the PNG has an indexed pixel format.
            ///
            /// - Parameters:
            ///     - data: tRNS chunk data. It must not contain more transparency
            ///         values than the PNG’s color depth can uniquely encode.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given transparency data
            ///         contains more than `palette.count` trasparency values.
            ///     - DecodingError.unexpectedChunk: If the PNG does not have an
            ///         indexed color format.
            public
            func decodetRNS(_ data: [UInt8], palette: inout [RGBA<UInt8>]) throws
            {
                guard self.code.isIndexed
                    else
                {
                    throw DecodingError.unexpectedChunk(.core(.transparency))
                }
                
                guard data.count <= palette.count
                    else
                {
                    throw DecodingError.invalidChunk(message: "indexed image contains too many transparency entries (\(data.count), expected \(palette.count))")
                }
                
                palette = zip(palette, data).map
                    {
                        $0.0.withAlpha($0.1)
                    }
                    +
                    palette.dropFirst(data.count)
            }
            
            /// Decodes the data of a tRNS chunk, validates, and returns a chroma key.
            ///
            /// This method should only be called if the PNG has an RGB or grayscale
            /// pixel format.
            ///
            /// - Parameters:
            ///     - data: tRNS chunk data. If this PNG has a grayscale pixel format,
            ///         it must contain one value sample. If this PNG has an RGB pixel
            ///         format, it must contain three samples, red, green, and blue.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given transparency data does not
            ///         contain the correct number of samples.
            ///     - DecodingError.unexpectedChunk: If the PNG does not have an
            ///         opaque color format.
            public
            func decodetRNS(_ data:[UInt8]) throws -> RGBA<UInt16>
            {
                switch self.code
                {
                case .v1, .v2, .v4, .v8, .v16:
                    guard data.count == 2
                        else
                    {
                        throw DecodingError.invalidChunk(message: "grayscale chroma key has wrong size (\(data.count) bytes, expected 2 bytes)")
                    }
                    
                    let q:UInt16 = quantum(depth: self.code.depth),
                    v:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
                    return .init(v)
                    
                case .rgb8, .rgb16:
                    guard data.count == 6
                        else
                    {
                        throw DecodingError.invalidChunk(message: "rgb chroma key has wrong size (\(data.count) bytes, expected 6 bytes)")
                    }
                    
                    let q:UInt16 = quantum(depth: self.code.depth),
                    r:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                    g:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                    b:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
                    return .init(r, g, b)
                    
                default:
                    throw DecodingError.unexpectedChunk(.core(.transparency))
                }
            }
        }
        
        public static let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        
        public var header: Header
        
        public var size: (width: Int, height: Int) {
            get {
                return header.size
            }
        }
        
        public var palette: [RGBA<UInt8>]?
        
        /// The pixel format of this PNG image, and its associated color palette,
        /// if applicable.
        public var format: Format
        
        /// The chroma key of this PNG image, if it has one.
        ///
        /// The alpha component of this property is ignored by the library.
        public
        var chromaKey: RGBA<UInt16>?
        
        /// The shape of a two-dimensional array containing this PNG image.
        var shape: Shape
        
        private var pitches: Pitches {
            let pitches: Pitches
            switch self.header.interlaceMethod
            {
            case .none:
                pitches = .init(shape: self.shape)
                
            case .adam7(let subImages):
                pitches = .init(subImages: subImages)
            }
            return pitches
        }
        
        /// The number of bytes needed to store the encoded image data of this PNG
        /// image.
        var byteCount:Int
        {
            switch self.header.interlaceMethod
            {
            case .none:
                return self.shape.byteCount
                
            case .adam7(let subImages):
                return subImages.reduce(0)
                {
                    $0 + $1.shape.byteCount
                }
            }
        }
        
        var decodedByteCount:Int
        {
            switch self.header.interlaceMethod
            {
            case .none:
                return self.shape.byteCount + self.shape.size.y
                
            case .adam7(let subImages):
                return subImages.reduce(0)
                {
                    $0 + $1.shape.byteCount + $1.shape.size.y
                }
            }
        }
        
        /// The buffer containing this PNG’s decoded, but not necessarily
        /// deinterlaced, image data.
        public internal(set)
        var data: [UInt8] = []
        
        public
        typealias Ancillaries = (unique: [Chunk], repeatable: [Chunk])
        /// Additional chunks not parsed by the library.
        public
        var ancillaries: Ancillaries = (unique: [], repeatable: [])
        
        /// The path of the image in the file
        public private(set) var path: String? = nil
        
        private
        enum DecompressionStage
        {
            case i                             // initial
            case ii(header: Header)  // IHDR sighted
            case iii(header: Header, palette:[RGBA<UInt8>]) // PLTE sighted
            case iv(decoder: WPXPNGDeocdable) // IDAT sighted
            case v      // IDAT ended
        }
        
        /// When data is uncomplete (like network)
        private class Parser {
            var isBgein = false
            var isFinished = false
            var source = Bytes.Source()
            var isIphonePNG = false
            var stage = DecompressionStage.i
            var seen = Bitfield<UInt16>()
        }
        
        private var parser = Parser()
        
        internal init() {
            self.header = Header(size: (width: 0, height: 0), code: .rgba8, interlaceMethod: .none)
            self.format = .rgba8(nil)
            self.shape = format.code.shape(from: (x: 0, y: 0))
        }
        
        public init(data: [UInt8]) throws {
            self.header = Header(size: (width: 0, height: 0), code: .rgba8, interlaceMethod: .none)
            self.format = .rgba8(nil)
            self.shape = format.code.shape(from: (x: 0, y: 0))
            try update(data: data)
        }
        
        public mutating func update(data: [UInt8]) throws {
            
            guard data.count >= 8 else {
                return
            }
            
            parser.source.update(data: data)
            
            if parser.isBgein == false {
                try parser.source.begin()
                parser.isBgein = true
            }
            
            guard var chunk = try parser.source.next() else {
                return
            }
            
            // make sure certain chunks don’t duplicate
            let index: Int
            switch chunk.chunkType
            {
            case .core(.header):
                index = 0
            case .core(.palette):
                index = 1
            case .core(.end):
                index = 2
            case .unique(.chromaticity):
                index = 3
            case .unique(.gamma):
                index = 4
            case .unique(.profile):
                index = 5
            case .unique(.significantBits):
                index = 6
            case .unique(.srgb):
                index = 7
            case .unique(.background):
                index = 8
            case .unique(.histogram):
                index = 9
            case .core(.transparency):
                index = 10
            case .unique(.physicalDimensions):
                index = 11
            case .unique(.time):
                index = 12
            default:
                index = -1
            }
            
            if index != -1, parser.seen.testAndSet(index) {
                throw DecodingError.duplicateChunk(chunk.chunkType)
            }
            
            while true
            {
                switch (chunk.chunkType, parser.stage)
                {
                case (.unique(.CgBI), .i):
                    parser.isIphonePNG = true
                case    (.core(.header), .i):
                    self.header = try .decodeIHDR(chunk.chunkData)
                    self.format = try Format(code: header.code, palette: [])
                    self.shape = format.code.shape(from: (x: header.size.width, y: header.size.height))
                    parser.stage   = .ii(header: self.header)
                    parser.seen[0] = true
                case    (_, .i):
                    throw DecodingError.missingChunk(.header)
                    
                case    (.core(.palette), .ii(let header)):
                    // call will throw if header does not have a color format
                    self.palette = try header.decodePLTE(chunk.chunkData)
                    self.format = try Format(code: header.code, palette: palette)
                    parser.stage = .iii(header: header, palette: self.palette!)
                    
                case    (.core(.palette), .iv):
                    throw DecodingError.unexpectedChunk(.core(.palette))
                    
                case    (.core(.data), .ii(let header)):
                    let format: Format
                    switch header.code
                    {
                    case .v1:
                        format = .v1
                    case .v2:
                        format = .v2
                    case .v4:
                        format = .v4
                    case .v8:
                        format = .v8
                    case .v16:
                        format = .v16
                    case .rgb8:
                        format = .rgb8(nil)
                    case .rgb16:
                        format = .rgb16(nil)
                    case .indexed1, .indexed2, .indexed4, .indexed8:
                        throw DecodingError.missingChunk(.palette)
                    case .va8:
                        format = .va8
                    case .va16:
                        format = .va16
                    case .rgba8:
                        format = .rgba8(nil)
                    case .rgba16:
                        format = .rgba16(nil)
                    }
                    
                    self.format = format
                    self.shape = format.code.shape(from: (x: header.size.width, y: header.size.height))
                    
                    parser.stage = .iv(decoder: parser.isIphonePNG ? try iphonePNGDecoder() : try self.decoder())
                    continue
                case    (.core(.data), .iii(let header, let palette)):
                    let format: Format
                    switch header.code
                    {
                    case .rgb8:
                        format = .rgb8(palette)
                    case .rgb16:
                        format = .rgb16(palette)
                    case .indexed1:
                        format = .indexed1(palette)
                    case .indexed2:
                        format = .indexed2(palette)
                    case .indexed4:
                        format = .indexed4(palette)
                    case .indexed8:
                        format = .indexed8(palette)
                    case .rgba8:
                        format = .rgba8(palette)
                    case .rgba16:
                        format = .rgba16(palette)
                    case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
                        fatalError("unreachable: `case (.PLTE, .ii(let header)):` should have blocked off this state")
                    }
                    
                    self.format = format
                    self.shape = format.code.shape(from: (x: header.size.width, y: header.size.height))
                    
                    parser.stage = .iv(decoder: parser.isIphonePNG ? try iphonePNGDecoder() : try self.decoder())
                    continue
                case    (.core(.data), .iv(var decoder)):
                    
                    var streamContinue = false
                    let result = try decoder.forEachScanline(decodedFrom: chunk.chunkData)
                    self.data = result.1
                    
                    streamContinue = result.0
                    
                    parser.stage = streamContinue ?
                        .iv(decoder: decoder) :
                        .v
                case (.core(.end), .v):
                    parser.isFinished = true
                    
                    return
                case    (.core(.end), .ii),
                        (.core(.end), .iii):
                    throw DecodingError.missingChunk(.data)
                    
                case    (.core(.transparency), .ii(let header)):
                    // call will throw if header does not have a v or rgb format
                    self.chromaKey = try header.decodetRNS(chunk.chunkData)
                case    (.core(.transparency), .iii(let header, var palette)):
                    // call will throw if header does not have a v or rgb format
                    try header.decodetRNS(chunk.chunkData, palette: &palette)
                    parser.stage = .iii(header: header, palette: palette)
                    
                case    (.unique(.background), .ii(let header)):
                    guard !header.code.isIndexed
                        else
                    {
                        throw DecodingError.missingChunk(.palette)
                    }
                    
                case    (.unique(.histogram),           .ii):
                    throw DecodingError.missingChunk(.palette)
                    
                case    (.core(.header),                .iii),
                        (.unique(.chromaticity),        .iii),
                        (.unique(.gamma),               .iii),
                        (.unique(.profile),             .iii),
                        (.unique(.srgb),                .iii),
                        
                        (.core(.header),                .v),
                        (.core(.palette),               .v),
                        (.core(.data),                  .v),
                        (.unique(.chromaticity),        .v),
                        (.unique(.gamma),               .v),
                        (.unique(.profile),             .v),
                        (.unique(.srgb),                .v),
                        
                        (.unique(.physicalDimensions),  .v),
                        (.repeatable(.suggestedPalette),.v),
                        
                        (.unique(.background),          .v),
                        (.unique(.histogram),           .v),
                        (.core(.transparency),          .v):
                    throw DecodingError.unexpectedChunk(chunk.chunkType)
                    
                default:
                    break
                }
                
                // record unrecognized ancillary chunks
                switch chunk.chunkType
                {
                case .core:
                    break
                case .unique:
                    ancillaries.unique.append(chunk)
                case .repeatable:
                    ancillaries.repeatable.append(chunk)
                }
                
                guard let nextChunk = try parser.source.next() else {
                    return
                }
                
                chunk = nextChunk
                // make sure certain chunks don’t duplicate
                let index:Int
                switch chunk.chunkType
                {
                case .core(.header):
                    index = 0
                case .core(.palette):
                    index = 1
                case .core(.end):
                    index = 2
                case .unique(.chromaticity):
                    index = 3
                case .unique(.gamma):
                    index = 4
                case .unique(.profile):
                    index = 5
                case .unique(.significantBits):
                    index = 6
                case .unique(.srgb):
                    index = 7
                case .unique(.background):
                    index = 8
                case .unique(.histogram):
                    index = 9
                case .core(.transparency):
                    index = 10
                case .unique(.physicalDimensions):
                    index = 11
                case .unique(.time):
                    index = 12
                default:
                    continue
                }
                
                guard !parser.seen.testAndSet(index)
                    else
                {
                    throw DecodingError.duplicateChunk(chunk.chunkType)
                }
            }
        }
        
        /// Initialize the PNG structure and extract the image
        ///
        /// - Parameter path: The path of the image in the file
        public init(path: String) throws {
            self.path = path
            self.header = Header(size: (width: 0, height: 0), code: .rgba8, interlaceMethod: .none)
            self.format = .rgba8(nil)
            self.shape = format.code.shape(from: (x: 0, y: 0))
            
            let file = File(path)
            try file.open()
                        
            try update(data: try file.readSomeBytes(count: file.size))
            
            file.close()
        }
        
        @_specialize(exported: true, where Component == UInt8)
        @_specialize(exported: true, where Component == UInt16)
        @_specialize(exported: true, where Component == UInt32)
        @_specialize(exported: true, where Component == UInt64)
        @_specialize(exported: true, where Component == UInt)
        public init<Component>(rgba: [RGBA<Component>], size: (width: Int, height: Int), to code: Format.Code, chromaKey: RGBA<UInt16>? = nil, ancillaries: Ancillaries = (unique: [], repeatable: [])) throws {
            // make sure pixel array is correct size
            guard rgba.count == size.width * size.height
                else
            {
                throw ConversionError.pixelCount
            }
            
            self.chromaKey = chromaKey
            let shape = code.shape(from: (x: size.width, y: size.height))
            self.shape = shape
            self.ancillaries = ancillaries
            
            self.header = Header.init(size: size, code: code, interlaceMethod: .none)
            
            let pixelCount = rgba.count
            
            let inLength = pixelCount * 4
            let dataCount = pixelCount * code.volume / 8
            
            let `in` = rgba.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            self.data = [UInt8](repeating: 0, count: dataCount)
            
            let out = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: dataCount) {
                    UnsafeMutablePointer<UInt8>(mutating: $0)
                }
            }
            
            switch code
            {
            case .v1, .v2, .v4, .v8, .v16:
                convert_rgba_to_v(`in`, out, inLength, UInt8(Component.bitWidth), UInt8(code.depth))
            case .va8, .va16:
                convert_rgba_to_va(`in`, out, inLength, UInt8(Component.bitWidth), UInt8(code.depth))
    
            case .rgb8, .rgb16:
                convert_rgba_to_rgb(`in`, out, inLength, UInt8(Component.bitWidth), UInt8(code.depth))
                
            case .rgba8, .rgba16:
                if Component.bitWidth == code.depth {
                    let baseAddress = rgba.withUnsafeBufferPointer {
                        $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: dataCount) {
                            $0
                        }
                    }
                    
                    let buffer = UnsafeBufferPointer<UInt8>(start: baseAddress, count: dataCount)
                    self.data = Array(buffer)
                    break
                }
                
                convert_rgba_to_rgba(`in`, out, inLength, UInt8(Component.bitWidth), UInt8(code.depth))
                
            case .indexed8, .indexed4, .indexed2, .indexed1:
                var palette: UnsafeMutablePointer<UInt8>?
                var paletteCount: UInt8 = 0
                defer {
                    palette?.deallocate()
                }
                
                let status = convert_rgba_to_index(`in`, out, &palette, &paletteCount, inLength, UInt8(Component.bitWidth), UInt8(code.depth))
                
                guard status == 0 else {
                    throw ConversionError.paletteOverflow
                }
                
                if let palette = palette {
                    let baseAddress = palette.withMemoryRebound(to: RGBA<UInt8>.self, capacity: Int(paletteCount)) {
                        $0
                    }
                    let buffer = UnsafeMutableBufferPointer<RGBA<UInt8>>(start: baseAddress, count: Int(paletteCount))
                    let paletteRGBAs = Array(buffer)
                    self.palette = paletteRGBAs
                }
            }
            
            self.format = try Format(code: code, palette: palette)
        }
        
        /// Encodes this PNG’s palette as the chunk data of a PLTE chunk, if it
        /// has one.
        ///
        /// This method always returns valid PLTE chunk data. If this `Properties`
        /// record has more palette entries than can be encoded with its color depth,
        /// only the first `1 << format.depth` entries are encoded. This method
        /// does not remove palette entries from this metatada record itself.
        ///
        /// - Returns: An array containing PLTE chunk data, or `nil` if this PNG
        ///     does not have a palette. The chunk header, length,
        ///     and crc32 tail are not included.
        public
        func encodePLTE() -> [UInt8]?
        {
            return self.format.palette?.prefix(1 << self.format.code.depth).flatMap
                {
                    [$0.r, $0.g, $0.b]
            }
        }
        
        /// Encodes this PNG’s transparency information as the chunk data of a tRNS
        /// chunk, if it has any.
        ///
        /// This method always returns valid tRNS chunk data. If this PNG has an
        /// indexed pixel format, and this `Properties` record has more palette entries
        /// than can be encoded with its color depth, then only the first `1 << format.depth`
        /// transparency values are encoded. This method does not remove palette
        /// entries from this `Properties` record itself.
        ///
        /// - Returns: An array containing tRNS chunk data, or `nil` if this PNG
        ///     does not have an transparency information. The chunk header, length,
        ///     and crc32 tail are not included. The chunk data consists of a single
        ///     grayscale chroma key value, narrowed to this PNG’s color depth,
        ///     if it has an opaque grayscale pixel format, an RGB chroma key triple,
        ///     narrowed to this PNG’s color depth, if it has an opaque RGB pixel
        ///     format, and the transparency values in this PNG’s color palette,
        ///     if it has an indexed color format. In the indexed color case, trailing
        ///     opaque palette entries are trimmed from the outputted sequence of
        ///     transparency values. If all palette entries are opaque, or this
        ///     `Properties` record has not been assigned a palette, `nil` is returned.
        public
        func encodetRNS() -> [UInt8]?
        {
            switch self.format
            {
            case .v1, .v2, .v4, .v8, .v16:
                guard let key:RGBA<UInt16> = self.chromaKey
                    else
                {
                    return nil
                }
                let quantization:Int = UInt16.bitWidth - self.format.code.depth
                return [key.r >> quantization].flatMap
                    {
                        [UInt8].store($0, asBigEndian: UInt16.self)
                }
                
            case .rgb8, .rgb16:
                guard let key:RGBA<UInt16> = self.chromaKey
                    else
                {
                    return nil
                }
                let quantization:Int = UInt16.bitWidth - self.format.code.depth
                return
                    [
                        key.r >> quantization,
                        key.g >> quantization,
                        key.b >> quantization
                        ].flatMap
                        {
                            [UInt8].store($0, asBigEndian: UInt16.self)
                }
                
            case    let .indexed1(palette),
                    let .indexed2(palette),
                    let .indexed4(palette),
                    let .indexed8(palette):
                
                var alphas:[UInt8] = palette.prefix(1 << self.format.code.depth).map{ $0.a }
                guard let last:Int = alphas.lastIndex(where: { $0 != UInt8.max })
                    else
                {
                    // palette is empty
                    return nil
                }
                
                alphas.removeLast(alphas.count - last - 1)
                return alphas.isEmpty ? nil : alphas
                
            default:
                return nil
            }
        }
        
        /// Compresses this image to data.
        ///
        /// - Parameters:
        ///     - recode: True is recode all contents, false is using source data if it's count > 0
        ///     - chunkSize: The maximum IDAT chunk size to use. The default is 65536 bytes.
        /// No meaning recode == false, source data count > 0
        ///     - level: The level of LZ77 compression to use. Must be in the,range `0 ... 9`, where 0 is no compression, and 9 is maximal compression.
        /// No meaning recode == false, source data count > 0
        /// - Returns: Image compressed data.
        public func encode(recode: Bool = false, chunkSize: Int = 1 << 16, level: Int = 9) throws -> [UInt8]
        {
            precondition(chunkSize >= 1, "chunk size must be positive")
            
            if recode == false, parser.source.data.count > 0 {
                return parser.source.data
            }
            
            var result = PNG.signature
            
            // partition ancillary chunks
            // before PLTE
            var leaders = self.ancillaries.repeatable
            
            // after PLTE (before IDAT)
            var trailers = [Chunk]()
            _ = self.ancillaries.unique.map {
                switch $0.chunkType {
                case .unique(.background), .unique(.histogram):
                    trailers.append($0)
                case .unique(.CgBI):
                    break
                default:
                    leaders.append($0)
                }
            }
            
            @inline(__always)
            func _next(_ chunkType: Chunk.ChunkType, _ contents: [UInt8] = []) throws
            {
                let tag = chunkType.tag
                var length: UInt32 = UInt32(bigEndian: UInt32(contents.count));
                let lengthPointer = withUnsafeBytes(of: &length) {
                    $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
                
                let header = [lengthPointer[0], lengthPointer[1], lengthPointer[2], lengthPointer[3], tag.name.0, tag.name.1, tag.name.2, tag.name.3]
                
                let partial: UInt = header.suffix(4).withUnsafeBufferPointer
                {
                    crc32(0, $0.baseAddress, 4)
                }
                
                // crc has 32 significant bits, padded out to a UInt
                let crc:UInt = crc32(partial, contents, UInt32(contents.count))
                
                result.append(contentsOf: header)
                result.append(contentsOf: contents)
                result.append(contentsOf: [UInt8].store(crc, asBigEndian: UInt32.self))
            }
            
            // IHDR
            try _next(.core(.header), self.header.encodeIHDR())
            
            // [leaders...]
            for chunk in leaders
            {
                try _next(chunk.chunkType, chunk.chunkData)
            }
            
            // PLTE
            try self.encodePLTE().map
            {
                try _next(.core(.palette), $0)
            }
            // tRNS
            try self.encodetRNS().map
            {
                try _next(.core(.transparency), $0)
            }
            
            // [trailers...]
            for chunk in trailers
            {
                try _next(chunk.chunkType, chunk.chunkData)
            }
            
            // [IDAT...]
            var encoder: Encoder = try self.encoder(level: level)
            let data = try encoder.encode()
            let dataCount = data.count
            var offset = 0
            let dataPointer = data.withUnsafeBytes {
                $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
            }
            while dataCount - offset >= chunkSize {
                let buffer = UnsafeBufferPointer<UInt8>(start: dataPointer + offset, count: chunkSize)
                try _next(.core(.data), Array(buffer))
                offset += chunkSize
            }
            
            if dataCount - offset > 0 {
                let buffer = UnsafeBufferPointer<UInt8>(start: dataPointer + offset, count: dataCount - offset)
                try _next(.core(.data), Array(buffer))
            }
            try _next(.core(.end))
            
            return result
        }
        
        /// Compresses this image, and outputs the compressed PNG file to the given outputPath.
        ///
        ///
        /// Excessively small chunk sizes may harm image compression. Higher
        /// compression levels produce smaller PNG files, but take longer to
        /// run.
        ///
        /// - Parameters:
        ///     - outputPath: A destination to write the contents of the
        ///         compressed file to.
        ///     - recode: True is recode all contents, false is using source data if it's count > 0
        ///     - chunkSize: The maximum IDAT chunk size to use. The default is 65536 bytes.
        /// No meaning recode == false, source data count > 0
        ///     - level: The level of LZ77 compression to use. Must be in the,range `0 ... 9`, where 0 is no compression, and 9 is maximal compression.
        /// No meaning recode == false, source data count > 0
        public func encode(to outputPath: String, recode: Bool = false, chunkSize: Int = 1 << 16, level: Int = 9) throws
        {
            precondition(chunkSize >= 1, "chunk size must be positive")
            
            let file = File(outputPath)
            try file.open(.write)
            defer {
                file.close()
            }
            
            if recode == false, parser.source.data.count > 0 {
                try file.write(bytes: parser.source.data)
                return
            }
            
            // write png signature
            try file.write(bytes: PNG.signature)
            
            // partition ancillary chunks
            // before PLTE
            var leaders = self.ancillaries.repeatable
            
            // after PLTE (before IDAT)
            var trailers = [Chunk]()
            _ = self.ancillaries.unique.map {
                switch $0.chunkType {
                case .unique(.background), .unique(.histogram):
                    trailers.append($0)
                case .unique(.CgBI):
                    break
                default:
                    leaders.append($0)
                }
            }
            
            @inline(__always)
            func _next(_ chunkType: Chunk.ChunkType, _ contents: [UInt8] = []) throws
            {
                let tag = chunkType.tag
                var length: UInt32 = UInt32(bigEndian: UInt32(contents.count));
                let lengthPointer = withUnsafeBytes(of: &length) {
                    $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
            
                let header = [lengthPointer[0], lengthPointer[1], lengthPointer[2], lengthPointer[3], tag.name.0, tag.name.1, tag.name.2, tag.name.3]
                
                let partial: UInt = header.suffix(4).withUnsafeBufferPointer
                {
                    crc32(0, $0.baseAddress, 4)
                }
                
                // crc has 32 significant bits, padded out to a UInt
                let crc:UInt = crc32(partial, contents, UInt32(contents.count))
                
                try file.write(bytes: header)
                try file.write(bytes: contents)
                try file.write(bytes: .store(crc, asBigEndian: UInt32.self))
            }
            
            // IHDR
            try _next(.core(.header), self.header.encodeIHDR())
            
            // [leaders...]
            for chunk in leaders
            {
                try _next(chunk.chunkType, chunk.chunkData)
            }
            
            // PLTE
            try self.encodePLTE().map
            {
                try _next(.core(.palette), $0)
            }
            // tRNS
            try self.encodetRNS().map
            {
                try _next(.core(.transparency), $0)
            }
            
            // [trailers...]
            for chunk in trailers
            {
                try _next(chunk.chunkType, chunk.chunkData)
            }
            
            // [IDAT...]
            var encoder: Encoder = try self.encoder(level: level)
            let data = try encoder.encode()
            let dataCount = data.count
            var offset = 0
            let dataPointer = data.withUnsafeBytes {
                $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
            }
            while dataCount - offset >= chunkSize {
                let buffer = UnsafeBufferPointer<UInt8>(start: dataPointer + offset, count: chunkSize)
                try _next(.core(.data), Array(buffer))
                offset += chunkSize
            }

            if dataCount - offset > 0 {
                let buffer = UnsafeBufferPointer<UInt8>(start: dataPointer + offset, count: dataCount - offset)
                try _next(.core(.data), Array(buffer))
            }
            try _next(.core(.end))
        }
    }
}

extension WPX.PNG {
    
    public struct Chunk {
        var length: UInt32
        var chunkType: ChunkType
        var chunkData: [UInt8]
        var crc: UInt32
        
        public func encode() -> [UInt8] {
            
            return [UInt8].store(length, asBigEndian: UInt32.self) + chunkType.encode() + chunkData + [UInt8].store(crc, asBigEndian: UInt32.self)
        }
        
        public enum ChunkType {
            case    core(Core),
            unique(Unique),
            repeatable(Repeatable)
            
            /// Classifies the given chunk tag.
            ///
            /// - Parameters:
            ///     - tag: A PNG chunk tag.
            public
            init(_ tag:Tag)
            {
                switch tag
                {
                case .IHDR:
                    self = .core(.header)
                case .PLTE:
                    self = .core(.palette)
                case .IDAT:
                    self = .core(.data)
                case .IEND:
                    self = .core(.end)
                case .tRNS:
                    self = .core(.transparency)
                    
                case .cHRM:
                    self = .unique(.chromaticity)
                case .gAMA:
                    self = .unique(.gamma)
                case .iCCP:
                    self = .unique(.profile)
                case .sBIT:
                    self = .unique(.significantBits)
                case .sRGB:
                    self = .unique(.srgb)
                case .bKGD:
                    self = .unique(.background)
                case .hIST:
                    self = .unique(.histogram)
                case .pHYs:
                    self = .unique(.physicalDimensions)
                case .tIME:
                    self = .unique(.time)
                case .CgBI:
                    self = .unique(.CgBI)
                    
                case .sPLT:
                    self = .repeatable(.suggestedPalette)
                case .iTXt:
                    self = .repeatable(.textUTF8)
                case .tEXt:
                    self = .repeatable(.textLatin1)
                case .zTXt:
                    self = .repeatable(.textLatin1Compressed)
                    
                default:
                    self = .repeatable(.other(.init(_tag: tag)))
                }
            }
            
            public var tag:Tag
            {
                switch self
                {
                case .core(let core):
                    return core.tag
                case .unique(let unique):
                    return unique.tag
                case .repeatable(let repeatable):
                    return repeatable.tag
                }
            }
            
            public func encode() -> [UInt8] {
                switch self {
                case .core(let c):
                    return [c.tag.name.0, c.tag.name.1, c.tag.name.2, c.tag.name.3]
                case .unique(let u):
                    return [u.tag.name.0, u.tag.name.1, u.tag.name.2, u.tag.name.3]
                case .repeatable(let r):
                    return [r.tag.name.0, r.tag.name.1, r.tag.name.2, r.tag.name.3]
                }
            }
        }
        
        /// A PNG chunk type recognized and parsed by the library.
        public
        enum Core
        {
            case    header,
            palette,
            data,
            end,
            transparency
            
            var tag:Tag
            {
                switch self
                {
                case .header:
                    return .IHDR
                case .palette:
                    return .PLTE
                case .data:
                    return .IDAT
                case .end:
                    return .IEND
                case .transparency:
                    return .tRNS
                }
            }
        }
        
        /// A PNG chunk type not parsed by the library, which can only occur
        /// once in a PNG file.
        public
        enum Unique
        {
            case    chromaticity,
            gamma,
            profile,
            significantBits,
            srgb,
            background,
            histogram,
            physicalDimensions,
            time,
            CgBI
            
            
            var tag:Tag
            {
                switch self
                {
                case .chromaticity:
                    return .cHRM
                case .gamma:
                    return .gAMA
                case .profile:
                    return .iCCP
                case .significantBits:
                    return .sBIT
                case .srgb:
                    return .sRGB
                case .background:
                    return .bKGD
                case .histogram:
                    return .hIST
                case .physicalDimensions:
                    return .pHYs
                case .time:
                    return .tIME
                case .CgBI:
                    return .CgBI
                }
            }
            
            /// Whether or not this chunk is safe to copy over if image data has
            /// been modified.
            public
            var safeToCopy:Bool
            {
                switch self
                {
                case .physicalDimensions:
                    return true
                default:
                    return false
                }
            }
        }
        
        /// A PNG chunk type not parsed by the library, which can occur multiple
        /// times in a PNG file.
        public
        enum Repeatable
        {
            case    suggestedPalette,
            textUTF8,
            textLatin1,
            textLatin1Compressed,
            other(Other)
            
            /// A non-standard private PNG chunk type.
            public
            struct Other
            {
                /// This chunk’s tag
                public
                let tag:Tag
                
                /// Creates a private PNG chunk type identifier from the given
                /// tag bytes.
                ///
                /// This initializer will trap if the given bytes do not form
                /// a valid chunk tag, or if the tag represents a chunk type
                /// defined by the library. To handle these situations, use the
                /// `Chunk(_:)` initializer and switch on its enumeration cases
                /// instead.
                ///
                /// - Parameters:
                ///     - name: The four bytes of this PNG chunk type’s name.
                public
                init(_ name:(UInt8, UInt8, UInt8, UInt8))
                {
                    guard let tag:Tag = Tag.init(name)
                        else
                    {
                        let string:String = .init(decoding: [name.0, name.1, name.2, name.3],
                                                  as: Unicode.ASCII.self)
                        fatalError("'\(string)' is not a valid chunk tag")
                    }
                    
                    switch ChunkType.init(tag)
                    {
                    case .repeatable(.other(let instance)):
                        self = instance
                        
                    default:
                        fatalError("'\(tag)' is a reserved chunk tag")
                    }
                }
                
                init(_tag tag:Tag)
                {
                    self.tag = tag
                }
            }
            
            var tag:Tag
            {
                switch self
                {
                case .suggestedPalette:
                    return .sPLT
                case .textUTF8:
                    return .iTXt
                case .textLatin1:
                    return .tEXt
                case .textLatin1Compressed:
                    return .zTXt
                case .other(let other):
                    return other.tag
                }
            }
            
            /// Whether or not this chunk is safe to copy over if image data has
            /// been modified.
            public
            var safeToCopy:Bool
            {
                switch self
                {
                case .textUTF8, .textLatin1, .textLatin1Compressed:
                    return true
                case .other(let other):
                    return other.tag.name.3 & (1 << 5) != 0
                case .suggestedPalette:
                    return false
                }
            }
        }
        
        /// A four-byte PNG chunk type identifier.
        public
        struct Tag: Hashable, Equatable, CustomStringConvertible
        {
            /// The four-byte name of this PNG chunk type.
            let name:Math<UInt8>.V4
            
            /// A string displaying the ASCII representation of this PNG chunk type’s name.
            public
            var description:String
            {
                return .init( decoding: [self.name.0, self.name.1, self.name.2, self.name.3],
                              as: Unicode.ASCII.self)
            }
            
            private
            init(_ a:UInt8, _ p:UInt8, _ r:UInt8, _ c:UInt8)
            {
                self.name = (a, p, r, c)
            }
            
            /// Creates the chunk type with the given name bytes, if they are valid.
            /// Returns `nil` if the ancillary bit (in byte 0) is set or the reserved
            /// bit (in byte 2) is set, and the ASCII name is not one of `IHDR`, `PLTE`,
            /// `IDAT`, `IEND`, `cHRM`, `gAMA`, `iCCP`, `sBIT`, `sRGB`, `bKGD`, `hIST`,
            /// `tRNS`, `pHYs`, `sPLT`, `tIME`, `iTXt`, `tEXt`, or `zTXt`.
            ///
            /// - Parameters:
            ///     - name: The four bytes of this PNG chunk type’s name.
            public
            init?(_ name:(UInt8, UInt8, UInt8, UInt8))
            {
                self.name = name
                switch self
                {
                // legal public chunks
                case .IHDR, .PLTE, .IDAT, .IEND,
                     .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS,
                     .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXt, .CgBI:
                    break
                    
                default:
                    guard name.0 & 0x20 != 0
                        else
                    {
                        return nil
                    }
                    
                    guard name.2 & 0x20 == 0
                        else
                    {
                        return nil
                    }
                }
            }
            
            /// Returns a Boolean value indicating whether two PNG chunk types are equal.
            ///
            /// Equality is the inverse of inequality. For any values `a` and `b`, `a == b`
            /// implies that `a != b` is `false`.
            ///
            /// - Parameters:
            ///     - lhs: A value to compare.
            ///     - rhs: Another value to compare.
            public static
                func == (a:Tag, b:Tag) -> Bool
            {
                return a.name == b.name
            }
            
            /// Hashes the name of this PNG chunk type by feeding it into the given
            /// hasher.
            ///
            /// - Parameters:
            ///     - hasher: The hasher to use when combining the components of this
            ///         instance.
            public
            func hash(into hasher:inout Hasher)
            {
                hasher.combine( self.name.0 << 24 |
                    self.name.1 << 16 |
                    self.name.2 <<  8 |
                    self.name.3)
            }
            
            /// The PNG header chunk type.
            public static
            let IHDR:Tag = .init(73, 72, 68, 82)
            /// The PNG animation control chunk type.
            public static
            let acTL:Tag = .init(0x61, 0x63, 0x54, 0x4C)
            /// The PNG frame control chunk type.
            public static
            let fcTL:Tag = .init(102, 99, 84, 76)
            /// The PNG image data chunk type.
            public static
            let fdAT:Tag = .init(102, 100, 65, 84)
            /// The PNG palette chunk type.
            public static
            let PLTE:Tag = .init(80, 76, 84, 69)
            /// The PNG image data chunk type.
            public static
            let IDAT:Tag = .init(73, 68, 65, 84)
            /// The PNG image end chunk type.
            public static
            let IEND:Tag = .init(73, 69, 78, 68)
            
            /// The PNG chromaticity chunk type.
            public static
            let cHRM:Tag = .init(99, 72, 82, 77)
            /// The PNG gamma chunk type.
            public static
            let gAMA:Tag = .init(103, 65, 77, 65)
            /// The PNG embedded ICC chunk type.
            public static
            let iCCP:Tag = .init(105, 67, 67, 80)
            /// The PNG significant bits chunk type.
            public static
            let sBIT:Tag = .init(115, 66, 73, 84)
            /// The PNG *s*RGB chunk type.
            public static
            let sRGB:Tag = .init(115, 82, 71, 66)
            /// The PNG background chunk type.
            public static
            let bKGD:Tag = .init(98, 75, 71, 68)
            /// The PNG histogram chunk type.
            public static
            let hIST:Tag = .init(104, 73, 83, 84)
            /// The PNG transparency chunk type.
            public static
            let tRNS:Tag = .init(116, 82, 78, 83)
            
            /// The PNG physical dimensions chunk type.
            public static
            let pHYs:Tag = .init(112, 72, 89, 115)
            
            /// The PNG suggested palette chunk type.
            public static
            let sPLT:Tag = .init(115, 80, 76, 84)
            /// The PNG time chunk type.
            public static
            let tIME:Tag = .init(116, 73, 77, 69)
            
            /// The PNG UTF-8 text chunk type.
            public static
            let iTXt:Tag = .init(105, 84, 88, 116)
            /// The PNG Latin-1 text chunk type.
            public static
            let tEXt:Tag = .init(116, 69, 88, 116)
            /// The PNG compressed Latin-1 text chunk type.
            public static
            let zTXt:Tag = .init(122, 84, 88, 116)
            
            /// The Apple PNG addtionall chunk.
            public static
            let CgBI:Tag = .init(67, 103, 66, 73)
        }
    }
    
    /// Errors that can occur while reading, decompressing, or decoding PNG files.
    public
    enum DecodingError:Error
    {
        /// A PNG file is missing its magic signature.
        case missingSignature
        
        /// A data interface is unable to provide requested data.
        case dataUnavailable
        
        /// An image data buffer does not match the shape specified by an associated
        /// `Properties` record
        case inconsistentMetadata
        
        /// A PNG chunk has a type-specific validity error.
        case invalidChunk(message:String)
        /// A PNG chunk has an invalid type name.
        case invalidName((UInt8, UInt8, UInt8, UInt8))
        
        /// A PNG chunk’s crc32 value indicates it has been corrupted.
        case corruptedChunk(Chunk.ChunkType)
        /// A PNG chunk has been encountered which cannot appear assuming a particular
        /// sequence of preceeding chunks have been encountered.
        case unexpectedChunk(Chunk.ChunkType)
        
        /// A PNG chunk has been encountered that is of the same type as a previously
        /// encountered chunk, and is of a type which cannot appear multiple times
        /// in the same PNG file.
        case duplicateChunk(Chunk.ChunkType)
        /// A prerequisite PNG chunk is missing.
        case missingChunk(Chunk.Core)
    }
    
    public
    enum ConversionError:Error
    {
        /// An input pixel array has the wrong size
        case pixelCount
        /// An image being encoded has too many colors to index.
        case paletteOverflow
        case missingPalette
        /// An indexed pixel references a palette entry that doesn’t exist.
        case indexOutOfRange
    }
    
    /// Errors that can occur while writing, compressing, or encoding PNG files.
    public
    enum EncodingError:Error
    {
        /// A data interface is unable to accept given data.
        case notAcceptingData
        /// An input scanline has the wrong size.
        case bufferCount
    }
    
    public enum ConvertError: Error {
        /// Is not iphone png
        case isNotCgBiPNG
        /// Uncompress out count error
        case uncompressLengthError
    }
}

// MARK: - Deocd
internal protocol WPXPNGDeocdable {
    /// The filter delay used by this image `Decoder`. This value is computed
    /// from the volume of a PNG pixel format, but has no meaning itself.
    var stride: Int { get }
    
    var pitches: WPX.PNG.Pitches { set get }
    
    mutating
    func forEachScanline(decodedFrom data: [UInt8])
        throws -> (Bool, [UInt8])
}

extension WPXPNGDeocdable {
    /// Defilters the given filtered scanline in-place, using the given
    /// reference scanline.
    ///
    /// - Parameters:
    ///     - scanline: The scanline to defilter in-place. The first byte
    ///         of the scanline is interpreted as the filter byte, and this
    ///         byte is set to 0 upon defiltering.
    ///     - reference: The defiltered scanline assumed to be immediately
    ///         above the given filtered scanline. This scanline should
    ///         contain all zeroes if the filtered scanline is logically
    ///         the first scanline in its (sub-)image. The first byte of
    ///         this scanline should always be a bogus padding byte corresponding
    ///         to the filter byte of a filtered scanline, such that
    ///         `reference.count == scanline.count`.
    fileprivate
    func defilter(_ scanline: inout [UInt8], reference: [UInt8])
    {
        assert(scanline.count == reference.count)
        
        let filter:UInt8              = scanline[scanline.startIndex]
        scanline[scanline.startIndex] = 0
        switch filter
        {
        case 0:
            break
            
        case 1: // sub
            for i:Int in scanline.indices.dropFirst(self.stride)
            {
                scanline[i] = scanline[i] &+ scanline[i - self.stride]
            }
            
        case 2: // up
            for i:Int in scanline.indices
            {
                scanline[i] = scanline[i] &+ reference[i]
            }
            
        case 3: // average
            for i:Int in scanline.indices.prefix(self.stride)
            {
                scanline[i] = scanline[i] &+ reference[i] >> 1
            }
            for i:Int in scanline.indices.dropFirst(self.stride)
            {
                let total:UInt16  = UInt16(scanline[i - self.stride]) +
                    UInt16(reference[i])
                scanline[i] = scanline[i] &+ UInt8(truncatingIfNeeded: total >> 1)
            }
            
        case 4: // paeth
            for i:Int in scanline.indices.prefix(self.stride)
            {
                scanline[i] = scanline[i] &+ WPX.PNG.paeth(0, reference[i], 0)
            }
            for i:Int in scanline.indices.dropFirst(self.stride)
            {
                let p:UInt8 =  WPX.PNG.paeth(scanline[i - self.stride],
                                             reference[i              ],
                                             reference[i - self.stride])
                scanline[i] = scanline[i] &+ p
            }
            
        default:
            break // invalid
        }
    }
    
    fileprivate
    func defilter(_ scanline: inout UnsafeMutableBufferPointer<UInt8>, reference: [UInt8])
    {
        assert(scanline.count == reference.count)
        
        let filter:UInt8              = scanline[scanline.startIndex]
        scanline[scanline.startIndex] = 0
        switch filter
        {
        case 0:
            break
            
        case 1: // sub
            for i:Int in scanline.indices.dropFirst(self.stride)
            {
                scanline[i] = scanline[i] &+ scanline[i - self.stride]
            }
            //            for i in self.stride..<scanline.count {
            //                scanline[i] = scanline[i] &+ scanline[i - self.stride]
        //            }
        case 2: // up
            for i:Int in scanline.indices
            {
                scanline[i] = scanline[i] &+ reference[i]
            }
            
        case 3: // average
            for i:Int in scanline.indices.prefix(self.stride)
            {
                scanline[i] = scanline[i] &+ reference[i] >> 1
            }
            for i:Int in scanline.indices.dropFirst(self.stride)
            {
                let total:UInt16  = UInt16(scanline[i - self.stride]) +
                    UInt16(reference[i])
                scanline[i] = scanline[i] &+ UInt8(truncatingIfNeeded: total >> 1)
            }
            
        case 4: // paeth
            for i:Int in scanline.indices.prefix(self.stride)
            {
                scanline[i] = scanline[i] &+ WPX.PNG.paeth(0, reference[i], 0)
            }
            for i:Int in scanline.indices.dropFirst(self.stride)
            {
                let p:UInt8 =  WPX.PNG.paeth(scanline[i - self.stride],
                                             reference[i              ],
                                             reference[i - self.stride])
                scanline[i] = scanline[i] &+ p
            }
            
        default:
            break // invalid
        }
    }
}

extension WPX.PNG {
    
    /// Returns the value of the paeth filter function with the given parameters.
    @inline(__always)
    fileprivate static
        func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
    {
        //        let v:Math<Int16>.V3 = Math.cast((a, b, c), as: Int16.self),
        //        p:Int16          = v.x + v.y - v.z
        //        let d:Math<Int16>.V3 = Math.abs(Math.sub((p, p, p), v))
        //
        //        if d.x <= d.y && d.x <= d.z
        //        {
        //            return a
        //        }
        //        else if d.y <= d.z
        //        {
        //            return b
        //        }
        //        else
        //        {
        //            return c
        //        }
        let pa = abs(Int16(b) - Int16(c))
        let pb = abs(Int16(a) - Int16(c))
        let pc = abs(Int16(a) + Int16(b) - Int16(c) - Int16(c))
        
        if pc < pa, pc < pb {
            return c
        } else if pb < pa {
            return b
        } else {
            return a
        }
    }
    
    public func decoder() throws -> Decoder {
        let inflator: LZ77.Inflator = try .init(outBufferCapacity: decodedByteCount)
        let pitches: Pitches,
        adam7: Bool
        switch self.header.interlaceMethod
        {
        case .none:
            pitches = .init(shape: self.shape)
            adam7 = false
        case .adam7(let subImages):
            pitches = .init(subImages: subImages)
            adam7 = true
        }
        
        return .init(bitsPerPixel: self.format.code.volume, bytesPerRow:self.shape.pitch, pitches: pitches, adam7: adam7, inflator: inflator)
    }
    
    public
    func iphonePNGDecoder() throws -> IphonePNGDecoder
    {
        let inflator: LZ77.Inflator = try .init(isApplePNG: true, outBufferCapacity: decodedByteCount)
        let pitches: Pitches
        let adam7: Bool
        switch self.header.interlaceMethod
        {
        case .none:
            pitches = .init(shape: self.shape)
            adam7 = false
        case .adam7(let subImages):
            pitches = .init(subImages: subImages)
            adam7 = true
        }
        return .init(bitsPerPixel: self.format.code.volume, bytesPerRow:self.shape.pitch, pitches: pitches, adam7: adam7, inflator: inflator)
    }
    
    /// A low level API for receiving and processing decompressed and decoded
    /// PNG image data at the scanline level.
    public
    struct Decoder: WPXPNGDeocdable
    {
        /// 上一扫描行，去滤波使用, 扫描图片第一行时为nil
        var reference: UnsafePointer<UInt8>? = nil
        
        /// The filter delay used by this image `Decoder`. This value is computed
        /// from the volume of a PNG pixel format, but has no meaning itself.
        internal let stride: Int
        /// bpp
        fileprivate let bitsPerPixel: Int
        /// Image bytes per row
        fileprivate let bytesPerRow: Int
        
        internal
        var pitches: Pitches,
        inflator: LZ77.Inflator
        
        var pixels = [UInt8]()
        var scanlineCount = 0
        var isAdam7 = false
        // 7次扫描的规则 isAdam7为真时以下成员才使用
        let startY = [0, 0, 4, 0, 2, 0, 1]
        let incY = [8, 8, 8, 4, 4, 2, 2]
        let startX = [0, 4, 0, 2, 0, 1, 0]
        let incX = [8, 8, 4, 4, 2, 2, 1]
        var subImageIndex = -1
        var xOffset = 0
        var yOffset = 0
        /// c扫描函数的变量设置
        var setting: DeinterlacedSetting?
        
        init(bitsPerPixel: Int, bytesPerRow: Int, pitches: Pitches, adam7: Bool, inflator: LZ77.Inflator)
        {
            self.stride   = max(1, bitsPerPixel >> 3)
            self.pitches  = pitches
            self.inflator = inflator
            self.bitsPerPixel = bitsPerPixel
            self.bytesPerRow = bytesPerRow
            self.isAdam7 = adam7
            
            if adam7 {
                pixels = [UInt8](repeating: UInt8.max, count: pitches.byteCount)
                setting = DeinterlacedSetting()
                let out = pixels.withUnsafeMutableBytes {
                    $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
                setting?.out = out
                setting?.bitsPerPixel = bitsPerPixel
                setting?.bytesPerRow = bytesPerRow
            }
            
            // transfer scanline to reference line
            if let pitch:Int? = self.pitches.next()
            {
                if let pitch:Int = pitch
                {
                    scanlineCount = pitch + 1
                    subImageIndex += 1
                    xOffset = startX[subImageIndex]
                    yOffset = startY[subImageIndex]
                }
            }
        }
        
        /// Calls the given closure for each complete scanline decoded from
        /// the given compressed image data, passing the decoded contents of
        /// the scanline to the closure.
        ///
        /// Individual data blocks can produce incomplete scanlines. These
        /// scanlines are stored and will be completed by subsequent data blocks,
        /// when they will be passed as full scanlines to the closures given
        /// in the later `forEachScanline(decodedFrom:_:)` calls.
        /// - Parameters:
        ///     - data: Compressed image data.
        /// - Returns: `true` if this `Decoder`’s LZ77 stream expects more input
        ///     data, and `false` otherwise. decoded pixels
        ///
        /// - Warning: Do not call this method again on the same instance after
        ///     it has returned `false`. Doing so will result in undefined behavior.
        
        public mutating func forEachScanline(decodedFrom data: [UInt8]) throws -> (Bool, [UInt8]) {
            let streamContinue = try self.inflator.push(input: data)

            if isAdam7 {
                while true
                {
                    xOffset = startX[subImageIndex]

                    if scanlineCount > 0, let scanline = inflator.scanline(lineCount: scanlineCount)
                    {
                        /** swift版本的去滤波过程，因为性能问题暂不使用，使用c函数替换
                         let buffer = UnsafeMutableBufferPointer<UInt8>(start: scanline, count: scanlineCount)
                         self.defilter(&buffer, reference: reference)
                         */


                        let filter = scanline[0]
                        scanline[0] = 0;
                        defilterScanline(scanline + 1, reference, stride, filter, scanlineCount - 1)
                        reference = UnsafePointer<UInt8>(scanline + 1)

                        /** swift版本的adam7扫描过程，因为性能问题暂不使用，使用c函数替换
                         var s = 1
                         while true {
                         if s >= scanlineCount {
                         break
                         }

                         let index = xOffset * stride + 600 * stride * yOffset

                         for i in 0..<stride {
                         pixels[index + i] = scanline[s + i]
                         }

                         xOffset += incX[subImageIndex]
                         s += stride
                         }*/

                        if var setting = setting {
                            setting.scanline = UnsafePointer<UInt8>(scanline + 1)
                            setting.length = scanlineCount - 1
                            setting.xOffset = xOffset
                            setting.incX = incX[subImageIndex]
                            setting.yOffset = yOffset
                            WPXPNGC.deinterlaced(&setting)
                            yOffset += incY[subImageIndex]
                        }

                        // transfer scanline to reference line
                        if let pitch:Int? = self.pitches.next()
                        {
                            if let pitch:Int = pitch
                            {
                                scanlineCount = pitch + 1
                                subImageIndex += 1
                                xOffset = startX[subImageIndex]
                                yOffset = startY[subImageIndex]
                            }
                        } else {
                            break
                        }

                    } else {
                        break
                    }
                }
            } else {
                while true
                {
                    if scanlineCount > 0, let scanline = inflator.scanline(lineCount: scanlineCount)
                    {
                        /** swift版本的去滤波过程，因为性能问题暂不使用，使用c函数替换
                         let buffer = UnsafeMutableBufferPointer<UInt8>(start: scanline, count: scanlineCount)
                         self.defilter(&buffer, reference: reference)
                         */

                        let filter = scanline[0]
                        scanline[0] = 0;
                        defilterScanline(scanline + 1, reference, stride, filter, scanlineCount - 1)

                        reference = UnsafePointer<UInt8>(scanline + 1)
                        let buffer = UnsafeMutableBufferPointer<UInt8>(start: scanline + 1, count: scanlineCount - 1)
                        pixels.append(contentsOf: buffer)

                        // transfer scanline to reference line
                        if let pitch:Int? = self.pitches.next()
                        {
                            if let pitch:Int = pitch
                            {
                                scanlineCount = pitch + 1
                            }
                        } else {
                            break
                        }
                    } else {
                        break
                    }
                }
            }

            guard streamContinue
                else
            {
                return (false, pixels)
            }

            guard self.inflator.unprocessedCount > 0
                else
            {
                // no input (encoded data) left

                return (true, pixels)
            }

            return (try self.inflator.test(), pixels)
        }
    }
    
    /// A low level API for receiving and processing decompressed and decoded
    /// PNG image data at the scanline level.
    public
    struct IphonePNGDecoder: WPXPNGDeocdable
    {
        /// The filter delay used by this image `Decoder`. This value is computed
        /// from the volume of a PNG pixel format, but has no meaning itself.
        internal let stride: Int
        /// bpp
        fileprivate let bitsPerPixel: Int
        /// Complete picture bytes per row
        fileprivate let bytesPerRow: Int
        
        internal
        var pitches: Pitches,
        inflator: LZ77.Inflator
        /// 当前扫描行长度
        var scanlineCount = 0
        /// 经过扫描过的像素数据
        var pixels = [UInt8]()
        // 是否是隔行扫描
        var isAdam7 = false
        // 7次扫描的规则 isAdam7为真时以下成员才使用
        let startY = [0, 0, 4, 0, 2, 0, 1]
        let incY = [8, 8, 8, 4, 4, 2, 2]
        let startX = [0, 4, 0, 2, 0, 1, 0]
        let incX = [8, 8, 4, 4, 2, 2, 1]
        var subImageIndex = -1
        var xOffset = 0
        var yOffset = 0
        /// c扫描函数的变量设置
        var setting: DeinterlacedSetting?
        
        init(bitsPerPixel: Int, bytesPerRow: Int, pitches: Pitches, adam7: Bool, inflator: LZ77.Inflator)
        {
            self.stride   = max(1, bitsPerPixel >> 3)
            self.pitches  = pitches
            self.inflator = inflator
            self.bitsPerPixel = bitsPerPixel
            self.bytesPerRow = bytesPerRow
            self.isAdam7 = adam7
            
            if adam7 {
                pixels = [UInt8](repeating: UInt8.max, count: pitches.byteCount)
                setting = DeinterlacedSetting()
                let out = pixels.withUnsafeMutableBytes {
                    $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
                setting?.out = out
                setting?.bitsPerPixel = bitsPerPixel
                setting?.bytesPerRow = bytesPerRow
            }
            
            // transfer scanline to reference line
            if let pitch:Int? = self.pitches.next()
            {
                if let pitch:Int = pitch
                {
                    scanlineCount = pitch + 1
                    subImageIndex += 1
                    xOffset = startX[subImageIndex]
                    yOffset = startY[subImageIndex]
                }
            }
        }
        
        /// Calls the given closure for each complete scanline decoded from
        /// the given compressed image data, passing the decoded contents of
        /// the scanline to the closure.
        ///
        /// Individual data blocks can produce incomplete scanlines. These
        /// scanlines are stored and will be completed by subsequent data blocks,
        /// when they will be passed as full scanlines to the closures given
        /// in the later `forEachScanline(decodedFrom:_:)` calls.
        /// - Parameters:
        ///     - data: Compressed image data.
        /// - Returns: `true` if this `Decoder`’s LZ77 stream expects more input
        ///     data, and `false` otherwise. decoded pixels
        ///
        /// - Warning: Do not call this method again on the same instance after
        ///     it has returned `false`. Doing so will result in undefined behavior.
        public mutating func forEachScanline(decodedFrom data:[UInt8]) throws -> (Bool, [UInt8])
        {
            let streamContinue = try self.inflator.push(input: data)
            
            if isAdam7 {
                while true
                {
                    xOffset = startX[subImageIndex]
                    if let scanline = inflator.scanline(lineCount: scanlineCount)
                    {
                        if var setting = setting {
                            setting.scanline = UnsafePointer<UInt8>(scanline + 1)
                            setting.length = scanlineCount - 1
                            setting.xOffset = xOffset
                            setting.incX = incX[subImageIndex]
                            setting.yOffset = yOffset
                            WPXPNGC.apple_png_deinterlaced(&setting)
                            yOffset += incY[subImageIndex]
                        }
                        
                        // transfer scanline to reference line
                        if let pitch:Int? = self.pitches.next()
                        {
                            if let pitch:Int = pitch
                            {
                                scanlineCount = pitch + 1
                                subImageIndex += 1
                                xOffset = startX[subImageIndex]
                                yOffset = startY[subImageIndex]
                            }
                        }
                        else
                        {
                            break
                        }
                        
                    } else {
                        break
                    }
                }
            } else {
                while true
                {
                    if let scanline = inflator.scanline(lineCount: scanlineCount)
                    {
                        /** 因为swift优化性能问题暂不使用以下代码，用c函数替换
                         // exchange B and R
                         for s in Swift.stride(from: 1, to: scanlineCount, by: stride) {
                         
                         // RGBA8 or RGBA16 demultiplyAlpha
                         if stride == 4 {
                         (scanline[s], scanline[s + 2]) = (scanline[s + 2], scanline[s])
                         // data[x+0] = (r*a) / 0xff; r = d[x+0] * 255 / a
                         let a = scanline[s + 3]
                         guard a > 0, a < UInt8.max else {
                         continue
                         }
                         
                         scanline[s + 0] = UInt8((Int(scanline[s + 0]) * Int(UInt8.max)) / Int(a))
                         scanline[s + 1] = UInt8((Int(scanline[s + 1]) * Int(UInt8.max)) / Int(a))
                         scanline[s + 2] = UInt8((Int(scanline[s + 2]) * Int(UInt8.max)) / Int(a))
                         
                         } else if stride == 8 {
                         (scanline[s], scanline[s + 1], scanline[s + 4], scanline[s + 5]) = (scanline[s + 4], scanline[s + 5], scanline[s], scanline[s + 1])
                         
                         let pointer = scanline.withMemoryRebound(to: UInt16.self, capacity: (scanlineCount - 1) / 2){
                         $0
                         }
                         
                         let a = pointer[s + 3]
                         guard a > 0, a < UInt16.max else {
                         continue
                         }
                         
                         pointer[s + 0] = UInt16((Int(pointer[s + 0]) * Int(UInt8.max)) / Int(a))
                         pointer[s + 1] = UInt16((Int(pointer[s + 1]) * Int(UInt8.max)) / Int(a))
                         pointer[s + 2] = UInt16((Int(pointer[s + 2]) * Int(UInt8.max)) / Int(a))
                         }
                         }*/
                        
                        apple_png_demultiply(scanline + 1, scanlineCount - 1, bitsPerPixel)
                        
                        let buffer = UnsafeMutableBufferPointer<UInt8>(start: scanline + 1, count: scanlineCount - 1)
                        pixels.append(contentsOf: buffer)
                        
                        // transfer scanline to reference line
                        if let pitch:Int? = self.pitches.next()
                        {
                            if let pitch:Int = pitch
                            {
                                scanlineCount = pitch + 1
                            }
                        }
                        else
                        {
                            break
                        }
                    } else {
                        break
                    }
                }
            }
            
            guard streamContinue
                else
            {
                return (false, pixels)
            }
            
            guard self.inflator.unprocessedCount > 0
                else
            {
                // no input (encoded data) left
                return (true, pixels)
            }
            
            
            return (try self.inflator.test(), pixels)
        }
    }
}


// MARK: - Encode
extension WPX.PNG {
    
    /// Initializes and returns a PNG `Encoder`.
    /// - Parameters:
    ///     - level: The compression level the returned `Encoder` will use.
    ///         Must be in the range `0 ... 9`, where 0 is no compression, and
    ///         9 is the highest possible amount of compression.
    /// - Returns: An image `Encoder` in its initial state.
    public
    func encoder(level: Int) throws -> Encoder
    {
        let deflator: LZ77.Deflator = try .init(level: level)
        
        return .init(bitsPerPixel: self.format.code.volume, shape: self.shape, interlaceMethod: self.header.interlaceMethod, deflator: deflator, data: data)
    }
    
    /// A low level API for filtering and compressing PNG image data at the
    /// scanline level.
    public
    struct Encoder
    {
        private var deflator: LZ77.Deflator
        
        let interlaceMethod: Interlacing
        
        var input: [UInt8]
        
        /// bpp
        fileprivate let bitsPerPixel: Int
        /// Complete picture bytes per row
        fileprivate let bytesPerRow: Int
        
        let shape: Shape
        
        init(bitsPerPixel: Int, shape: Shape, interlaceMethod: Interlacing, deflator: LZ77.Deflator, data: [UInt8])
        {
            self.deflator = deflator
            self.interlaceMethod = interlaceMethod
            
            self.input = data
            self.shape = shape
            self.bitsPerPixel = bitsPerPixel
            self.bytesPerRow = shape.pitch
        }
        
        public mutating func encode() throws -> [UInt8] {
            
            var out: [UInt8]
            switch interlaceMethod {
            case .none:
                out = [UInt8](repeating: 0, count: shape.byteCount + shape.size.y)
                interlacing_none_and_filter(&input, input.count, bitsPerPixel, bytesPerRow, &out)
            case .adam7(let subImages):
                let count = subImages.reduce(0) {
                    $0 + $1.shape.byteCount + $1.shape.size.y
                }
                out = [UInt8](repeating: 0, count: count)
                interlacing_adam7_and_filter(&input, input.count, bitsPerPixel, bytesPerRow, &out)
            }
        
            self.deflator.push(input: out)

            return try self.deflator.pull()
        }
        /** 性能问题暂不使用了
        public mutating func encode() throws -> [UInt8] {
            var stride = max(1, bitsPerPixel >> 3)
            var reference: UnsafePointer<UInt8>?
            guard case .adam7(let subImages) = interlaceMethod else {
                var scanlineCount = bytesPerRow
                var scanlineOffset = 0;
                while scanlineOffset < input.count {
                    let row = input.withUnsafeBytes {
                        ($0.baseAddress! + scanlineOffset).assumingMemoryBound(to: UInt8.self)
                    }
                    
                    scanlineOffset += bytesPerRow
                    
                    var scanline = [UInt8](repeating: 0, count: scanlineCount + 1)
                    
                    filterScanline(row, &scanline, reference, scanlineCount, stride)
                    
                    self.deflator.push(input: scanline)
                    
                    reference = row
                }
                
                return try self.deflator.pull()
            }
            
            
            let count = subImages.reduce(0) {
                $0 + $1.shape.byteCount + $1.shape.size.y
            }
            
            var out = [UInt8](repeating: 0, count: count)
            
            
            interlacing_adam72(&input, input.count, bitsPerPixel, bytesPerRow, &out)
            for image in subImages {
                reference = nil
                scanlineCount = image.shape.pitch
                for _ in image.strider.y {
                    let row = out.withUnsafeBytes {
                        ($0.baseAddress! + scanlineOffset).assumingMemoryBound(to: UInt8.self)
                    }
                    var scanline = [UInt8](repeating: 0, count: scanlineCount + 1)
                    filterScanline(row, &scanline, reference, scanlineCount, stride)
                    
                    self.deflator.push(input: scanline)
                    
                    reference = row
                    scanlineOffset += scanlineCount
                }
            }
            
            return try self.deflator.pull()
        }*/
    }
}

// MARK: - Aboue scale
extension WPX.PNG {
    
    /// Returns the size of one unit in a component of the given depth, in units of
    /// this color’s `Component` type.
    /// - Parameters:
    ///     - depth: A bit depth less than or equal to `Component.bitWidth`.
    /// - Returns: The size of one unit in a component of the given bit depth,
    ///     in units of `Component`. Multiplying this value with the scalar
    ///     integer value of a component of bit depth `depth` will renormalize
    ///     it to the range of `Component`.
    @inline(__always)
    static
        func quantum<Component>(depth:Int) -> Component
        where Component:FixedWidthInteger & UnsignedInteger
    {
        return Component.max / (Component.max &>> (Component.bitWidth - depth))
    }
    
    /// Returns the given color sample premultiplied with the given alpha sample.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - color: A color sample.
    ///     - alpha: An alpha sample.
    /// - Returns: The product of the given color sample and the given alpha
    ///     sample. The resulting value is accurate to within 1 `Component` unit.
    @usableFromInline
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
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
    
    /// Returns the given component widened to the given type, preserving its normalized
    /// value.
    ///
    /// `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - component: The component to upscale.
    ///     - type: The destination type.
    /// - Returns: The given component, normalized to the range of `T`.
    @inline(__always)
    static
        func upscale<Component, T>(_ component:Component, to type:T.Type) -> T
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        assert(T.bitWidth >= Component.bitWidth)
        return .init(truncatingIfNeeded: component) * quantum(depth: Component.bitWidth)
    }
    
    /// Returns the given component narrowed to the given type, preserving its normalized
    /// value.
    ///
    /// `T.bitWidth` must be less than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - component: The component to downscale.
    ///     - type: The destination type.
    /// - Returns: The given component, normalized to the range of `T`.
    @inline(__always)
    static
        func downscale<Component, T>(_ component:Component, to type:T.Type) -> T
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        assert(T.bitWidth <= Component.bitWidth)
        return .init(truncatingIfNeeded: component &>> (Component.bitWidth - T.bitWidth))
    }
    
    /// Returns the given component scaled to the given type, preserving its normalized
    /// value.
    ///
    /// - Parameters:
    ///     - component: The component to rescale.
    ///     - type: The destination type.
    /// - Returns: The given component, normalized to the range of `T`.
    @inline(__always)
    static
        func rescale<Component, T>(_ component:Component, to type:T.Type) -> T
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        // this branch should be gone in specialized form. it seems to be
        // effectively free.
        if T.bitWidth > Component.bitWidth
        {
            return upscale(component, to: T.self)
        }
        else
        {
            return downscale(component, to: T.self)
        }
    }
    
    
    /// Returns the given color with its components widened to the given type, preserving
    /// their normalized values.
    ///
    /// `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - va: A grayscale-alpha color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static
        func upscale<Component, T>(_ va:VA<Component>, to type:T.Type) -> VA<T>
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(upscale(va.v, to: T.self), upscale(va.a, to: T.self))
    }
    
    /// Returns the given color with its components narrowed to the given type, preserving
    /// their normalized values.
    ///
    /// `T.bitWidth` must be less than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - va: A grayscale-alpha color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static
        func downscale<Component, T>(_ va:VA<Component>, to type:T.Type) -> VA<T>
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(downscale(va.v, to: T.self), downscale(va.a, to: T.self))
    }
    
    /// Returns the given color with its components scaled to the given type, preserving
    /// their normalized values.
    ///
    /// - Parameters:
    ///     - va: A grayscale-alpha color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static
        func rescale<Component, T>(_ va:VA<Component>, to type:T.Type) -> VA<T>
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        if T.bitWidth > Component.bitWidth
        {
            return upscale(va, to: T.self)
        }
        else
        {
            return downscale(va, to: T.self)
        }
    }
    
    
    /// Returns the given color with its components narrowed to the given type, preserving
    /// their normalized values.
    ///
    /// `T.bitWidth` must be less than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static
        func downscale<Component, T>(_ rgba:RGBA<Component>, to type:T.Type) -> RGBA<T>
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(   downscale(rgba.r, to: T.self),
                        downscale(rgba.g, to: T.self),
                        downscale(rgba.b, to: T.self),
                        downscale(rgba.a, to: T.self))
    }
    
    /// Returns the given color with its components widened to the given type, preserving
    /// their normalized values.
    ///
    /// `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static
        func upscale<Component, T>(_ rgba:RGBA<Component>, to type:T.Type) -> RGBA<T>
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(   upscale(rgba.r, to: T.self),
                        upscale(rgba.g, to: T.self),
                        upscale(rgba.b, to: T.self),
                        upscale(rgba.a, to: T.self))
    }
    
    /// Returns the given color with its components scaled to the given type, preserving
    /// their normalized values.
    ///
    /// - Parameters:
    ///     - rgba: An RGBA color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static
        func rescale<Component, T>(_ rgba:RGBA<Component>, to type:T.Type) -> RGBA<T>
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        if T.bitWidth > Component.bitWidth
        {
            return upscale(rgba, to: T.self)
        }
        else
        {
            return downscale(rgba, to: T.self)
        }
    }
    
    /// Returns the given color with its alpha component set to 0 if its
    /// color value matches this PNG image’s chroma key, and the given color
    /// unchanged otherwise.
    ///
    /// - Parameters:
    ///     - color: An RGBA color to test.
    /// - Returns: The given color, with its alpha component set to 0 if its
    ///         color value matches this PNG image’s chroma key.
    @inline(__always)
    private
    func greenscreen<Component>(_ color:RGBA<Component>) -> RGBA<Component>
    {
        // hope this gets inlined
        guard let key:RGBA<Component> = Component.bitWidth > 16 ?
             (self.chromaKey.map{ WPX.PNG.upscale(  $0, to: Component.self) }) : (self.chromaKey.map{ WPX.PNG.downscale($0, to: Component.self) })
        
            else
        {
            return color
        }
        
        return color.equals(opaque: key) ? color.withAlpha(0) : color
    }
    
    @inline(__always)
    private
    func greenscreen<Component>(v:Component) -> RGBA<Component>
    {
        return self.greenscreen(.init(v))
    }
    
    @inline(__always)
    private
    func greenscreen<Component>(r:Component, g:Component, b:Component)
        -> RGBA<Component>
    {
        return self.greenscreen(.init(r, g, b))
    }
    
    /// Returns the given color as a grayscale-alpha color with its alpha
    /// component set to 0 if its RGB color value matches this PNG image’s
    /// chroma key, and `Component.max` otherwise.
    ///
    /// - Parameters:
    ///     - color: A grayscale-alpha color to test.
    /// - Returns: The given color, with its alpha component set to 0 if its
    ///         color value matches this PNG image’s chroma key.
    @inline(__always)
    private
    func greenscreen<Component>(_ color:RGBA<Component>) -> VA<Component>
    {
        // hope this gets inlined
        guard let key:RGBA<Component> = Component.bitWidth > 16 ?
            (self.chromaKey.map{ WPX.PNG.upscale(  $0, to: Component.self) }) :
            (self.chromaKey.map{ WPX.PNG.downscale($0, to: Component.self) })
            else
        {
            return color.va
        }
        
        return color.equals(opaque: key) ? color.va.withAlpha(0) : color.va
    }
    
    @inline(__always)
    private
    func greenscreen<Component>(v:Component) -> VA<Component>
    {
        return self.greenscreen(.init(v))
    }
    
    @inline(__always)
    private
    func greenscreen<Component>(r:Component, g:Component, b:Component)
        -> VA<Component>
    {
        return self.greenscreen(.init(r, g, b))
    }
    
    /// Returns a row-major matrix of the grayscale-alpha color values represented
    /// by all the pixels in this PNG image, normalized to the range of
    /// the given component type.
    ///
    /// If this image has grayscale color, the grayscale-alpha colors returned
    /// share the value component, and have `Component.max` in the alpha
    /// component. If this image has RGB color, the grayscale-alpha colors
    /// have the red component in the value component, and have `Component.max`
    /// in the alpha component. If this image has RGBA color, the grayscale-alpha
    /// colors share the alpha component in addition.
    ///
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
    /// `UInt64`, and `UInt`.
    ///
    /// - Parameters:
    ///     - type: An integer type.
    /// - Returns: A row-major matrix of grayscale-alpha pixel colors, normalized
    ///     to the given `Component` type, or `nil` if this image requires
    ///     a palette, and it does not have one.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    func va<Component>(of type:Component.Type) -> [VA<Component>]
        where Component:FixedWidthInteger & UnsignedInteger
    {
        let pixelCount = self.header.size.width * self.header.size.height
        let newComponents = 2
        var inLength = data.count
        let outLength = pixelCount * newComponents
        let bitDepth: UInt8 = UInt8(self.format.code.depth)
        switch self.format
        {
        case .v1, .v2, .v4:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
            
        case .v8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .v16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .va8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            var out = UnsafeMutablePointer<Component>.allocate(capacity: 0)
            defer {
                if !(Component.self is UInt8.Type) {
                    out.deallocate()
                }
            }
            if !(Component.self is UInt8.Type) {
                out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
                out.initialize(repeating: 0, count: outLength)
            } else {
                let rgbaPointer = `in`.withMemoryRebound(to: Component.self, capacity: pixelCount) {
                    $0
                }
                
                out = UnsafeMutablePointer<Component>(mutating: rgbaPointer)
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                break
                
            case is UInt16.Type:
                convert_va8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength)
                
            case is UInt32.Type:
                convert_va8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
                
            default:
                convert_va8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .va16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            var out = UnsafeMutablePointer<Component>.allocate(capacity: 0)
            defer {
                if !(Component.self is UInt16.Type) {
                    out.deallocate()
                }
            }
            if !(Component.self is UInt16.Type) {
                out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
                out.initialize(repeating: 0, count: outLength)
            } else {
                let rgbaPointer = `in`.withMemoryRebound(to: Component.self, capacity: pixelCount) {
                    $0
                }
                
                out = UnsafeMutablePointer<Component>(mutating: rgbaPointer)
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                convert_va16_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength)
                
            case is UInt16.Type:
                break;
                
            case is UInt32.Type:
                convert_va16_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
                
            default:
                convert_va16_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .rgb8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .rgb16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .rgba8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            var out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_rgba8_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength)
                
            case is UInt16.Type:
                convert_rgba8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength)
                
            case is UInt32.Type:
                convert_rgba8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
                
            default:
                convert_rgba8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            
            return Array(buffer)
            
        case .rgba16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            var out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_rgba16_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength)
                
            case is UInt16.Type:
                convert_rgba16_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength)
                
            case is UInt32.Type:
                convert_rgba16_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
                
            default:
                convert_rgba16_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            
            return Array(buffer)
            
        case    .indexed1(let palette),
                .indexed2(let palette),
                .indexed4(let palette):
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_index_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, palettePointer)
            case is UInt16.Type:
                convert_index_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, palettePointer)
            case is UInt32.Type:
                convert_index_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, palettePointer)
            default:
                convert_index_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, palettePointer)
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case    .indexed8(let palette):
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            out.initialize(repeating: 0, count: outLength)
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: VA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_index8_to_va8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, palettePointer)
            case is UInt16.Type:
                convert_index8_to_va16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, palettePointer)
            case is UInt32.Type:
                convert_index8_to_va32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, palettePointer)
            default:
                convert_index8_to_va64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, palettePointer)
            }
            
            let buffer = UnsafeMutableBufferPointer<VA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
        }
    }
    /** 因为swift性能问题暂不使用以下代码
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    func va<Component>(of type:Component.Type) -> [VA<Component>]
        where Component:FixedWidthInteger & UnsignedInteger
    {
        switch self.format
        {
        case .v1, .v2, .v4:
            return self.mapBitIntensity(self.greenscreen(v:))
            
        case .v8:
            return self.mapIntensity(from: UInt8.self,  self.greenscreen(v:))
            
        case .v16:
            return self.mapIntensity(from: UInt16.self, self.greenscreen(v:))
            
        case .va8:
            return self.mapIntensity(from: UInt8.self,  VA.init(_:_:))
            
        case .va16:
            return self.mapIntensity(from: UInt16.self, VA.init(_:_:))
            
        case .rgb8:
            return self.mapIntensity(from: UInt8.self,  self.greenscreen(r:g:b:))
            
        case .rgb16:
            return self.mapIntensity(from: UInt16.self, self.greenscreen(r:g:b:))
            
        case .rgba8:
            return self.mapIntensity(from: UInt8.self)
            {
                .init($0, $3)
            }
            
        case .rgba16:
            return self.mapIntensity(from: UInt16.self)
            {
                .init($0, $3)
            }
            
        case    .indexed1(let palette),
                .indexed2(let palette),
                .indexed4(let palette):
            
            // map over raw sample values instead of scaled values
            return self.mapBits
                {
                    (index:Int) in
                    return WPX.PNG.upscale(palette[index].va, to: Component.self)
            }
            
        case    .indexed8(let palette):
            return self.map(from: UInt8.self)
            {
                (index:Int) in
                
                return WPX.PNG.upscale(palette[index].va, to: Component.self)
            }
        }
    }*/
    
    /// Returns a row-major matrix of the RGBA color values represented
    /// by all the pixels in this PNG image, normalized to the range of
    /// the given component type.
    ///
    /// If this image has grayscale color, the RGBA colors returned have
    /// the value component in the red, green, and blue components, and
    /// `Component.max` in the alpha component. If this image has grayscale-alpha
    /// color, the RGBA colors returned share the alpha component in addition.
    /// If this image has RGB color, the RGBA colors share the red, green,
    /// and blue components, and have `Component.max` in the alpha component.
    ///
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    ///
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
    /// `UInt64`, and `UInt`.
    ///
    /// - Parameters:
    ///     - type: An integer type.
    /// - Returns: A row-major matrix of RGBA pixel colors, normalized to
    ///     the given `Component` type, or `nil` if this image requires
    ///     a palette, and it does not have one.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    func rgba<Component>(of type:Component.Type) -> [RGBA<Component>]
        where Component:FixedWidthInteger & UnsignedInteger
    {
        var start = CACurrentMediaTime()
        let pixelCount = self.header.size.width * self.header.size.height
        let newComponents = 4
        var inLength = data.count
        let outLength = pixelCount * newComponents
        let bitDepth: UInt8 = UInt8(self.format.code.depth)
        
        switch self.format
        {
        case .v1, .v2, .v4:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, chromaKeyPointer)
                } else {
                    convert_v_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .v8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_v8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .v16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }

            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_v16_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_v16_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .va8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
          
            switch type {
            case is UInt8.Type:
                convert_va8_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength)
                
            case is UInt16.Type:
                convert_va8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength)
                
            case is UInt32.Type:
                convert_va8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
                
            default:
                convert_va8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .va16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                convert_va16_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength)
                
            case is UInt16.Type:
                convert_va16_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength)
                
            case is UInt32.Type:
                convert_va16_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)

            default:
                convert_va16_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .rgb8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
                
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .rgb16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch type {
            case is UInt8.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, nil)
                }
                
            case is UInt16.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, nil)
                }
               
            case is UInt32.Type:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, nil)
                }
                
            default:
                if var chromaKey = self.chromaKey {
                    let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                        $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                            $0
                        }
                    }
                    convert_rgb16_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, chromaKeyPointer)
                } else {
                    convert_rgb16_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, nil)
                }
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case .rgba8:
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            var out = UnsafeMutablePointer<Component>.allocate(capacity: 0)
            defer {
                if !(Component.self is UInt8.Type) {
                    out.deallocate()
                }
            }
            if !(Component.self is UInt8.Type) {
                out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
                memset(out, 0, outLength * (Component.bitWidth >> 3))
            } else {
                let rgbaPointer = `in`.withMemoryRebound(to: Component.self, capacity: pixelCount) {
                    $0
                }
                
                out = UnsafeMutablePointer<Component>(mutating: rgbaPointer)
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch Component.self {
            case is UInt8.Type:
                break
                
            case is UInt16.Type:
                convert_rgba8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength)
                
            case is UInt32.Type:
                convert_rgba8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
                
            default:
                convert_rgba8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            
            return Array(buffer)
            
            
        case .rgba16:
            inLength = inLength / 2
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out: UnsafeMutablePointer<Component>
            defer {
                if !(Component.self is UInt16.Type) {
                    out.deallocate()
                }
            }
            if !(Component.self is UInt16.Type) {
                out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
                memset(out, 0, outLength * (Component.bitWidth >> 3))
            } else {
                let rgbaPointer = `in`.withMemoryRebound(to: Component.self, capacity: pixelCount) {
                    $0
                }
                
                out = UnsafeMutablePointer<Component>(mutating: rgbaPointer)
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_rgba16_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength)
                
            case is UInt16.Type:
               break
                
            case is UInt32.Type:
                convert_rgba16_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength)
            
            default:
                convert_rgba16_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength)
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        case    .indexed1(let palette),
                .indexed2(let palette),
                .indexed4(let palette):
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_index_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, palettePointer)
            case is UInt16.Type:
                convert_index_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, palettePointer)
            case is UInt32.Type:
                convert_index_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, palettePointer)
            default:
                convert_index_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, palettePointer)
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            
            return Array(buffer)
            
        case    .indexed8(let palette):
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<Component>.allocate(capacity: outLength)
            memset(out, 0, outLength * (Component.bitWidth >> 3))
            defer {
                out.deallocate()
            }
            
            let baseAddress = out.withMemoryRebound(to: RGBA<Component>.self, capacity: pixelCount) {
                $0
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            switch Component.self {
            case is UInt8.Type:
                convert_index8_to_rgba8(`in`, (out as! UnsafeMutablePointer<UInt8>), inLength, bitDepth, palettePointer)
            case is UInt16.Type:
                convert_index8_to_rgba16(`in`, (out as! UnsafeMutablePointer<UInt16>), inLength, bitDepth, palettePointer)
            case is UInt32.Type:
                convert_index8_to_rgba32(`in`, (out as! UnsafeMutablePointer<UInt32>), inLength, bitDepth, palettePointer)
            default:
                convert_index8_to_rgba64(`in`, (out as! UnsafeMutablePointer<UInt64>), inLength, bitDepth, palettePointer)
            }
            
            let buffer = UnsafeMutableBufferPointer<RGBA<Component>>(start: baseAddress, count: pixelCount)
            return Array(buffer)
            
        }
    }
    
    /* 因为swift性能问题暂不使用以下代码
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public
    func rgba<Component>(of type:Component.Type) -> [RGBA<Component>]
        where Component:FixedWidthInteger & UnsignedInteger
    {
        switch self.properties.format
        {
        case .v1, .v2, .v4:
            return self.mapBitIntensity(self.greenscreen(v:))
            
        case .v8:
            return self.mapIntensity(from: UInt8.self,  self.greenscreen(v:))
            
        case .v16:
            return self.mapIntensity(from: UInt16.self, self.greenscreen(v:))
            
        case .va8:
            return self.mapIntensity(from: UInt8.self,  RGBA.init(_:_:))
            
        case .va16:
            return self.mapIntensity(from: UInt16.self, RGBA.init(_:_:))
            
        case .rgb8:
            return self.mapIntensity(from: UInt8.self,  self.greenscreen(r:g:b:))
            
        case .rgb16:
            return self.mapIntensity(from: UInt16.self, self.greenscreen(r:g:b:))
            
        case .rgba8:
            return self.mapIntensity(from: UInt8.self,  RGBA.init(_:_:_:_:))
            
        case .rgba16:
            return self.mapIntensity(from: UInt16.self, RGBA.init(_:_:_:_:))
            
        case    .indexed1(let palette),
                .indexed2(let palette),
                .indexed4(let palette):
            // map over raw sample values instead of scaled values
            return self.mapBits
                {
                    (index:Int) in
                    
                    // palette component type is always UInt8 so all Swift
                    // unsigned integer types can be used as an unscaling
                    // target
                    return upscale(palette[index], to: Component.self)
            }
            
        case    .indexed8(let palette):
            // same as above except loading byte-size samples
            return self.map(from: UInt8.self)
            {
                (index:Int) in
                
                return upscale(palette[index], to: Component.self)
            }
        }
    }*/
 
    
    /// Returns a row-major matrix of the RGBA color values represented
    /// by all the pixels in this PNG image, normalized to the range of
    /// the given component type and encoded as integer slugs containing
    /// four components in ARGB order. The alpha components are premultiplied
    /// into the colors.
    ///
    /// If this image has grayscale color, the RGBA colors returned have
    /// the value component in the red, green, and blue components, and
    /// `Component.max` in the alpha component. If this image has grayscale-alpha
    /// color, the RGBA colors returned share the alpha component in addition.
    /// If this image has RGB color, the RGBA colors share the red, green,
    /// and blue components, and have `Component.max` in the alpha component.
    /// The RGBA colors are packed into four-component integer slugs of a
    /// type large enough to hold four instances of the given type, if one
    /// exists. The color components are packed in ARGB order, with alpha
    /// in the high bits.
    ///
    /// Allowed `Component` types by default are `UInt8`, and `UInt16`.
    /// Custom `Component` types can be used by conforming them to the
    /// `FusedVector4Element` protocol and supplying the `FusedVector4`
    /// associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
    ///
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    ///
    /// *Specialized* for `Component` types `UInt8` and `UInt16`.
    /// (`Component.FusedVector4` types `UInt32` and `UInt64`.)
    ///
    /// - Parameters:
    ///     - type: An integer type.
    /// - Returns: A row-major matrix of RGBA pixel colors, normalized to
    ///     the given `Component` type, and encoded as four-component integer
    ///     slugs, or `nil` if this image requires a palette, and
    ///     it does not have one.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    public
    func argbPremultiplied<Component>(of type:Component.Type)
        -> [Component.FusedVector4] where Component:FusedVector4Element
    {
        // *all* color formats can produce pixels with alpha, so we might
        // as well call the `rgba(of:)` function and let map fusion
        // optimize it
        return self.rgba(of: Component.self).map
            {
                $0.premultiplied.argb
        }
    }
    
    @inline(__always)
    private
    func load<Sample>(bits:Range<Int>, as _:Sample.Type) -> Sample
        where Sample:FixedWidthInteger
    {
        let byte:Int      = bits.lowerBound >> 3,
        bit:Int       = bits.lowerBound & 7,
        offset:Int    = UInt8.bitWidth - bits.count
        return .init(truncatingIfNeeded: (self.data[byte] &<< bit) &>> offset)
    }
    
    @inline(__always)
    private
    func load<T, Sample>(bigEndian:T.Type, at index:Int, as _:Sample.Type) -> Sample
        where T:FixedWidthInteger, Sample:FixedWidthInteger
    {
        assert(T.bitWidth <= Sample.bitWidth)
        
        return self.data.withUnsafeBufferPointer
            {
                let offset:Int               = index * MemoryLayout<T>.stride,
                raw:UnsafeRawPointer     = .init($0.baseAddress! + offset),
                pointer:UnsafePointer<T> = raw.bindMemory(to: T.self, capacity: 1)
                return .init(truncatingIfNeeded: T(bigEndian: pointer.pointee))
        }
    }
    
    @inline(__always)
    private
    func scale<T, Sample>(bigEndian:T.Type, at index:Int, to _:Sample.Type) -> Sample
        where T:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
    {
        let load = self.load(bigEndian: T.self, at: index, as: T.self)
        return WPX.PNG.rescale(load, to: Sample.self)
    }
    
    private
    func mapBits<Sample, Result>(_ body:(Sample) -> Result) -> [Result]
        where Sample:FixedWidthInteger
    {
        assert(self.format.code.depth < Sample.bitWidth)
        
        return withoutActuallyEscaping(body)
        {
            (body:@escaping (Sample) -> Result) in
            
            let depth:Int = self.format.code.depth,
            count:Int = self.format.code.volume * self.shape.size.x
            return stride(from: 0, to: self.data.count, by: self.shape.pitch).flatMap
                {
                    (i:Int) -> LazyMapSequence<StrideTo<Int>, Result> in
                    
                    let base:Int = i << 3
                    return stride(from: base, to: base + count, by: depth).lazy.map
                        {
                            body(self.load(bits: $0 ..< $0 + depth, as: Sample.self))
                    }
            }
        }
    }
    
    private
    func map<Atom, Sample, Result>(from _:Atom.Type, _ body:(Sample) -> Result) -> [Result]
        where Atom:FixedWidthInteger, Sample:FixedWidthInteger
    {
        assert(self.format.code.depth == Atom.bitWidth)
        
        return (0 ..< Math.vol(self.shape.size)).map
            {
                return body(self.load(bigEndian: Atom.self, at: $0, as: Sample.self))
        }
    }
    
    private
    func mapBitIntensity<Sample, Result>(_ body:(Sample) -> Result) -> [Result]
        where Sample:FixedWidthInteger & UnsignedInteger
    {
        assert(Sample.bitWidth >= 8)
        return self.mapBits
            {
                return body($0 * WPX.PNG.quantum(depth: self.format.code.depth))
        }
    }
    
    private
    func mapIntensity<Atom, Sample, Result>(from _:Atom.Type,
                                            _ body:(Sample) -> Result) -> [Result]
        where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
    {
        assert(self.format.code.depth == Atom.bitWidth)
        
        return (0 ..< Math.vol(self.shape.size)).map
            {
                return body(self.scale(bigEndian: Atom.self, at: $0, to: Sample.self))
        }
    }
    
    private
    func mapIntensity<Atom, Sample, Result>(from _:Atom.Type,
                                            _ body:(Sample, Sample) -> Result) -> [Result]
        where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
    {
        assert(self.format.code.depth == Atom.bitWidth)
        
        return (0 ..< Math.vol(self.shape.size)).map
            {
                return body(
                    self.scale(bigEndian: Atom.self, at: $0 << 1,     to: Sample.self),
                    self.scale(bigEndian: Atom.self, at: $0 << 1 | 1, to: Sample.self))
        }
    }
    
    private
    func mapIntensity<Atom, Sample, Result>(from _:Atom.Type,
                                            _ body:(Sample, Sample, Sample) -> Result) -> [Result]
        where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
    {
        assert(self.format.code.depth == Atom.bitWidth)
        
        return (0 ..< Math.vol(self.shape.size)).map
            {
                return body(
                    self.scale(bigEndian: Atom.self, at: $0 * 3,      to: Sample.self),
                    self.scale(bigEndian: Atom.self, at: $0 * 3 + 1,  to: Sample.self),
                    self.scale(bigEndian: Atom.self, at: $0 * 3 + 2,  to: Sample.self))
        }
    }
    
    private
    func mapIntensity<Atom, Sample, Result>(from _:Atom.Type,
                                            _ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result]
        where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
    {
        assert(self.format.code.depth == Atom.bitWidth)
    
        return (0 ..< Math.vol(self.shape.size)).map
            {
                return body(
                    self.scale(bigEndian: Atom.self, at: $0 << 2,      to: Sample.self),
                    self.scale(bigEndian: Atom.self, at: $0 << 2 | 1,  to: Sample.self),
                    self.scale(bigEndian: Atom.self, at: $0 << 2 | 2,  to: Sample.self),
                    self.scale(bigEndian: Atom.self, at: $0 << 2 | 3,  to: Sample.self))
        }
    }
}

// MARK: - UIKit/UIImage
#if os(macOS)

#elseif os(iOS)
extension WPX.PNG {
    public var iosImage: UIImage? {
        var components = self.format.code.components
        
        var pointer = self.data.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: self.data.count) {
                UnsafeMutablePointer<UInt8>(mutating: $0)
            }
        }
        
        var bitsPerComponent = self.format.code.volume / components
        var bytesPerRow = self.shape.pitch
        
        let colorSpaceRef: CGColorSpace
        let bitmapInfo: CGBitmapInfo
        
        var deallocate: (() -> Void)?
        
        switch self.format {
        case .indexed1(let palette),
             .indexed2(let palette),
             .indexed4(let palette),
             .indexed8(let palette):
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            let pixelCount = self.header.size.width * self.header.size.height
            let inLength = data.count
            let outLength = pixelCount * 4
            
            let `in` = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            deallocate = {
                pointer.deallocate()
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            convert_index_to_rgba8(`in`, pointer, inLength, UInt8(format.code.depth), palettePointer)
            components = 4
            bitsPerComponent = 8
            bytesPerRow = Format.rgba8(nil).code.shape(from: (x: size.width, y: size.height)).pitch
        case .v1, .v2, .v4:
            colorSpaceRef = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            let pixelCount = self.header.size.width * self.header.size.height
            let inLength = data.count
            let outLength = pixelCount * 2
            pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            
            deallocate = {
                pointer.deallocate()
            }
            
            let input = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_v_to_va8(input, pointer, inLength, UInt8(self.format.code.depth), chromaKeyPointer)
            } else {
                convert_v_to_va8(input, pointer, inLength, UInt8(self.format.code.depth), nil)
            }
            bytesPerRow = Format.va8.code.shape(from: (x: size.width, y: size.height)).pitch
            bitsPerComponent = 16
        case .v8, .v16:
            colorSpaceRef = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        case .va8:
            colorSpaceRef = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            components = 1
            bitsPerComponent = 16
        case .va16:
            let pixelCount = self.header.size.width * self.header.size.height
            let inLength = data.count / 2
            let outLength = pixelCount * 2
            pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            deallocate = {
                pointer.deallocate()
            }
            let input = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            convert_va16_to_va8(input, pointer, inLength)
            colorSpaceRef = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            bytesPerRow = Format.va8.code.shape(from: (x: size.width, y: size.height)).pitch
            components = 1
            bitsPerComponent = 16
        case .rgb8(_):
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
            let pixelCount = self.header.size.width * self.header.size.height
            let inLength = data.count
            let outLength = pixelCount * 4
            pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            deallocate = {
                pointer.deallocate()
            }
            
            let input = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_rgb8_to_rgba8(input, pointer, inLength, chromaKeyPointer)
            } else {
                convert_rgb8_to_rgba8(input, pointer, inLength, nil)
            }
            components = 4
            bytesPerRow = Format.rgba8(nil).code.shape(from: (x: size.width, y: size.height)).pitch
        case .rgb16(_):
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
            let pixelCount = self.header.size.width * self.header.size.height
            let inLength = data.count / 2
            let outLength = pixelCount * 4 * 2
            pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            let output = pointer.withMemoryRebound(to: UInt16.self, capacity: outLength / 2) {
                $0
            }
            
            deallocate = {
                pointer.deallocate()
            }
            
            let input = self.data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_rgb16_to_rgba16(input, output, inLength, chromaKeyPointer)
            } else {
                convert_rgb16_to_rgba16(input, output, inLength, nil)
            }
            
            bitsPerComponent = 16
            components = 4
            bytesPerRow = Format.rgba16(nil).code.shape(from: (x: size.width, y: size.height)).pitch
        case .rgba8(_), .rgba16(_):
            colorSpaceRef = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        }
        
        guard let context = CGContext(data: pointer, width: size.width, height: size.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpaceRef, bitmapInfo: bitmapInfo.rawValue), let imageRefExtended = context.makeImage() else {
            deallocate?()
            return nil
        }
        
        deallocate?()
        
        return UIImage(cgImage: imageRefExtended)
    }
}
#endif
