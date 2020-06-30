//
//  WPXAPNG.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/19.
//  Copyright © 2019 葬花桥. All rights reserved.
//

extension WPX {
    
    public struct APNG {
        public static let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        
        public typealias Header = PNG.Header
        public typealias Format = PNG.Format
        internal typealias Shape = PNG.Shape
        internal typealias Pitches = PNG.Pitches
        typealias Interlacing = PNG.Interlacing
        
        public var header: Header {
            didSet {
                defaultImage.header = header
            }
        }
        
        public var palette: [RGBA<UInt8>]? {
            didSet {
                defaultImage.palette = palette
            }
        }
        
        /// The pixel format of this PNG image, and its associated color palette,
        /// if applicable.
        public var format: Format {
            didSet {
                defaultImage.format = format
            }
        }
        
        /// The chroma key of this PNG image, if it has one.
        ///
        /// The alpha component of this property is ignored by the library.
        public
        var chromaKey: RGBA<UInt16>? {
            didSet {
                defaultImage.chromaKey = chromaKey
            }
        }
        
        /// The shape of a two-dimensional array containing this PNG image.
        var shape: Shape {
            didSet {
                defaultImage.shape = shape
            }
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
        
        public
        typealias Ancillaries = (unique: [Chunk], repeatable: [Chunk])
        /// Additional chunks not parsed by the library.
        public
        var ancillaries: Ancillaries = (unique: [], repeatable: [])
        
        /// The path of the image in the file
        public private(set) var path: String? = nil
        
        public private(set) var defaultImage: PNG = PNG()
        
        public var defaultIsFirstFrmae = true
        
        public struct AnimationControl {
            var numFrames: Int
            var numPlays: Int
            init(frameData: [UInt8]) {
                numFrames = Int(frameData.withUnsafeBytes {
                    $0.load(as: UInt32.self)
                    }.bigEndian)
                
                numPlays = Int(frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: MemoryLayout<UInt32>.size, as: UInt32.self)
                    }.bigEndian)
            }
        }
        
        public var animationControl: AnimationControl?
        
        public struct FrameControl {
            public var sequenceNumber: UInt32  ///< sequence number of the animation chunk, starting from 0
            public var width: UInt32            ///< width of the following frame
            public var height: UInt32           ///< height of the following frame
            public var xOffset: UInt32         ///< x position at which to render the following frame
            public var yOffset: UInt32         ///< y position at which to render the following frame
            public var delayNum: UInt16        ///< frame delay fraction numerator
            public var delayDen: UInt16        ///< frame delay fraction denominator
            public var disposeOp: DisposeOpType
            public var blendOp: BlendOpType
            
            public enum DisposeOpType: UInt8 {
                case none, // no disposal is done on this frame before rendering the next; the contents of the output buffer are left as is.
                background, // the frame's region of the output buffer is to be cleared to fully transparent black before rendering the next frame.
                previous // the frame's region of the output buffer is to be reverted to the previous contents before rendering the next frame.
            }
            
            public enum BlendOpType: UInt8 {
                case source, // all color components of the frame, including alpha, overwrite the current contents of the frame's output buffer region
                over // the frame should be composited onto the output buffer based on its alpha, using a simple OVER operation as described in the "Alpha Channel Processing"
            }
            
            init() {
                sequenceNumber = 0
                width = 0
                height = 0
                xOffset = 0
                yOffset = 0
                delayNum = 0
                delayDen = 0
                disposeOp = .none
                blendOp = .source
            }
            
            init(frameData: [UInt8]) {
                sequenceNumber = frameData.withUnsafeBytes {
                    $0.load(as: UInt32.self)
                    }.bigEndian
                
                var offset = 4
                
                width = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt32.self)
                    }.bigEndian
                offset += 4
                
                
                height = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt32.self)
                    }.bigEndian
                offset += 4
                
                xOffset = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt32.self)
                    }.bigEndian
                offset += 4
                
                yOffset = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt32.self)
                    }.bigEndian
                offset += 4
                
                delayNum = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt16.self)
                    }.bigEndian
                offset += 2
                
                delayDen = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt16.self)
                    }.bigEndian
                offset += 2
                
                let disposeOp = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt8.self)
                    }.bigEndian
                offset += 1
                
                let blendOp = frameData.withUnsafeBytes {
                    $0.load(fromByteOffset: offset, as: UInt8.self)
                    }.bigEndian
                
                switch disposeOp {
                case 0:
                    self.disposeOp = .none
                case 1:
                    self.disposeOp = .background
                case 2:
                    self.disposeOp = .previous
                default:
                    // error dispose_op value
                    self.disposeOp = .none
                }
                
                switch blendOp {
                case 0:
                    self.blendOp = .source
                case 1:
                    self.blendOp = .over
                default:
                    // error blend_op value
                    self.blendOp = .source
                }
            }
        }
        
        public struct Frame {
            public var frameControl: FrameControl
            public var png: PNG
        }
        
        public var frames: [Frame] = []
        
        private
        enum DecompressionStage
        {
            case i                             // initial
            case ii  // IHDR sighted
            case iii // PLTE sighted
            case iv(animationControl: AnimationControl)
            case v(frameControl: FrameControl?, decoder: WPXPNGDeocdable) // IDAT sighted
            case vi      // IDAT ended
        }
        
        /// When data is uncomplete (like network)
        private class Parser {
            var isBgein = false
            var isFinished = false
            var source = Bytes.Source()
            var isIphonePNG = false
            var outputBuffer: [UInt8]?
            var stage = DecompressionStage.i
            var seen = Bitfield<UInt16>()
        }
        
        private var parser = Parser()
        
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
            case .core(.animationControl):
                index = 13
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
                    parser.stage   = .ii
                    parser.seen[0] = true
                case    (_, .i):
                    throw DecodingError.missingChunk(.header)
                    
                case    (.core(.palette), .ii):
                    // call will throw if header does not have a color format
                    let palette = try header.decodePLTE(chunk.chunkData)
                    self.palette = palette
                    self.format = try Format(code: header.code, palette: palette)
                    parser.stage = .iii
                case    (.core(.palette), .iv):
                    // call will throw if header does not have a color format
                    let palette = try header.decodePLTE(chunk.chunkData)
                    self.palette = palette
                    self.format = try Format(code: header.code, palette: palette)
                case (.core(.animationControl), .ii):
//                    guard format.code.volume == 32 else {
//                        throw DecodingError.invalidColor(format.code)
//                    }
                    
                    let acTL = AnimationControl(frameData: chunk.chunkData)
                    self.animationControl = acTL
                    parser.stage = .iv(animationControl: acTL)
                case (.core(.animationControl), .iii): // is apng image
//                    guard format.code.volume >= 24 else {
//                        throw DecodingError.invalidColor(format.code)
//                    }
                    let acTL = AnimationControl(frameData: chunk.chunkData)
                    self.animationControl = acTL
                    parser.stage = .iv(animationControl: acTL)
                    
                case (.core(.frameControl), .iv(_)):
                    // the default image is first frame
                    let fcTL = FrameControl(frameData: chunk.chunkData)
                    let shape = format.code.shape(from: (x: Int(fcTL.width), y: Int(fcTL.height)))
                    parser.stage = .v(frameControl: fcTL, decoder: parser.isIphonePNG ? try iphonePNGDecoder(shape: shape) : try self.decoder(shape: shape))
                case (.core(.frameControl), .vi):
                    let fcTL = FrameControl(frameData: chunk.chunkData)
                    let shape = format.code.shape(from: (x: Int(fcTL.width), y: Int(fcTL.height)))
                    parser.stage = .v(frameControl: fcTL, decoder: parser.isIphonePNG ? try iphonePNGDecoder(shape: shape) : try self.decoder(shape: shape))
                case (.core(.frameControl), .v):
                    // duplicateChunk fctl chunk
                    throw DecodingError.unexpectedChunk(chunk.chunkType)
                    
                case    (.core(.data), .ii): // is png image
                    parser.stage = .v(frameControl: nil, decoder: parser.isIphonePNG ? try iphonePNGDecoder(shape: shape) : try self.decoder(shape: shape))
                    continue
                case    (.core(.data), .iii):
                    parser.stage = .v(frameControl: nil, decoder: parser.isIphonePNG ? try iphonePNGDecoder(shape: shape) : try self.decoder(shape: shape))
                    continue
                case (.core(.data), .iv(_)):
                    // the default png image is not a frame
                    defaultIsFirstFrmae = false
                    let shape = format.code.shape(from: (x: header.size.width, y: header.size.height))
                    parser.stage = .v(frameControl: nil, decoder: parser.isIphonePNG ? try iphonePNGDecoder(shape: shape) : try self.decoder(shape: shape))
                    
                case    (.core(.data), .v(let frameControl, var decoder)):
                    var streamContinue = false
                    let result = try decoder.forEachScanline(decodedFrom: chunk.chunkData)
                    streamContinue = result.0
                    parser.stage = streamContinue ?
                        .v(frameControl: frameControl, decoder: decoder) :
                        .vi
                    
                    self.defaultImage.data = result.1
                    
                    if !streamContinue {
                        if let fcTL = frameControl, parser.outputBuffer == nil {
                            if defaultIsFirstFrmae {
                                parser.outputBuffer = result.1
                            }
                            
                            let frame = Frame(frameControl: fcTL, png: defaultImage)
                            frames.append(frame)
                        } else {
                            if let fcTL = frameControl {
                                let frame = self.frame(fcTL: fcTL, rgba: result.1, buffer: &(parser.outputBuffer!))
                                frames.append(frame)
                            } else {
                                if defaultIsFirstFrmae {
                                    throw DecodingError.corruptedChunk(chunk.chunkType)
                                }
                            }
                        }
                    }
                    
                case (.core(.fData), .v(let frameControl, var decoder)):
                    var contents = chunk.chunkData
                    contents.removeFirst(4)
                    var streamContinue = false
                    let result = try decoder.forEachScanline(decodedFrom: contents)
                    streamContinue = result.0
                    parser.stage = streamContinue ?
                        .v(frameControl: frameControl, decoder: decoder) :
                        .vi
                    if !streamContinue {
                        if let fcTL = frameControl, parser.outputBuffer == nil {
                            parser.outputBuffer = result.1
                            let frame = Frame(frameControl: fcTL, png: defaultImage)
                            frames.append(frame)
                        } else {
                            if let fcTL = frameControl {
                                
                                let frame = self.frame(fcTL: fcTL, rgba: result.1, buffer: &(parser.outputBuffer!))
                                frames.append(frame)
                            }
                        }
                    }

                case    (_, .v):
                    throw DecodingError.unexpectedChunk(chunk.chunkType)
                case    (.core(.end), .vi):
                    parser.isFinished = true
                    
                    // Check frame number
                    if let acTL = animationControl, acTL.numFrames != frames.count {
                        throw DecodingError.frameNumber(needful: acTL.numFrames, actual: frames.count)
                    }
                    
                    return
                case    (.core(.end), .ii),
                        (.core(.end), .iii):
                    throw DecodingError.missingChunk(.data)
                    
                case    (.core(.transparency), .ii):
                    // call will throw if header does not have a v or rgb format
                    self.chromaKey = try header.decodetRNS(chunk.chunkData)
                case    (.core(.transparency), .iii):
                    // call will throw if header does not have a v or rgb format
                    guard var palette = palette else {
                        throw DecodingError.missingChunk(.palette)
                    }
                    try header.decodetRNS(chunk.chunkData, palette: &palette)
                    parser.stage = .iii
                    
                case    (.unique(.background), .ii):
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
                        
                        (.core(.header),                .vi),
                        (.core(.palette),               .vi),
                        (.core(.data),                  .vi),
                        (.unique(.chromaticity),        .vi),
                        (.unique(.gamma),               .vi),
                        (.unique(.profile),             .vi),
                        (.unique(.srgb),                .vi),
                        
                        (.unique(.physicalDimensions),  .vi),
                        (.repeatable(.suggestedPalette),.vi),
                        
                        (.unique(.background),          .vi),
                        (.unique(.histogram),           .vi),
                        (.core(.transparency),          .vi):
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
                    let tag = PNG.Chunk.Tag(chunk.chunkType.tag.name)
                    let chunkType = PNG.Chunk.ChunkType(tag!)
                    let chunk = PNG.Chunk(length: chunk.length, chunkType: chunkType, chunkData: chunk.chunkData, crc: chunk.crc)
                    defaultImage.ancillaries.unique.append(chunk)
                case .repeatable:
                    ancillaries.repeatable.append(chunk)
                    let tag = PNG.Chunk.Tag(chunk.chunkType.tag.name)
                    let chunkType = PNG.Chunk.ChunkType(tag!)
                    let chunk = PNG.Chunk(length: chunk.length, chunkType: chunkType, chunkData: chunk.chunkData, crc: chunk.crc)
                    defaultImage.ancillaries.repeatable.append(chunk)
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
    }
}

extension WPX.APNG {
    
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
                case .acTL:
                    self = .core(.animationControl)
                case .fcTL:
                    self = .core(.frameControl)
                case .IDAT:
                    self = .core(.data)
                case .fdAT:
                    self = .core(.fData)
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
            animationControl,
            frameControl,
            data,
            fData,
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
                case .animationControl:
                    return .acTL
                case .frameControl:
                    return .fcTL
                case .data:
                    return .IDAT
                case .fData:
                    return .fdAT
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
        
        /// APNG color type should be rgba8.
        case invalidColor(Format.Code)
        /// APNG frame number error.
        case frameNumber(needful: Int, actual: Int)
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

extension WPX.APNG {
    func decoder(shape: Shape) throws -> WPX.PNG.Decoder {
        var decodedByteCount = 0
        let pitches: Pitches,
        adam7: Bool
        switch self.header.interlaceMethod
        {
        case .none:
            decodedByteCount = self.shape.byteCount + self.shape.size.y
            pitches = .init(shape: shape)
            adam7 = false
        case .adam7(let subImages):
            decodedByteCount = subImages.reduce(0)
            {
                $0 + $1.shape.byteCount + $1.shape.size.y
            }
            pitches = .init(subImages: subImages)
            adam7 = true
        }
        
        let inflator: WPX.PNG.LZ77.Inflator = try .init(outBufferCapacity: decodedByteCount)
        return .init(bitsPerPixel: self.format.code.volume, bytesPerRow:self.shape.pitch, pitches: pitches, adam7: adam7, inflator: inflator)
    }
    
    func iphonePNGDecoder(shape: Shape) throws -> WPX.PNG.IphonePNGDecoder
    {
        var decodedByteCount = 0
        let pitches: Pitches,
        adam7: Bool
        switch self.header.interlaceMethod
        {
        case .none:
            decodedByteCount = self.shape.byteCount + self.shape.size.y
            pitches = .init(shape: shape)
            adam7 = false
        case .adam7(let subImages):
            decodedByteCount = subImages.reduce(0)
            {
                $0 + $1.shape.byteCount + $1.shape.size.y
            }
            pitches = .init(subImages: subImages)
            adam7 = true
        }
        
        let inflator: WPX.PNG.LZ77.Inflator = try .init(isApplePNG: true, outBufferCapacity: decodedByteCount)
        return .init(bitsPerPixel: self.format.code.volume, bytesPerRow:self.shape.pitch, pitches: pitches, adam7: adam7, inflator: inflator)
    }
}

import WPXPNGC
extension WPX.APNG {
    private func rgba(data: [UInt8], size: (width: Int, height: Int), format: Format) -> [UInt8]
    {
        let pixelCount = size.width * size.height
        let newComponents = 4
        var inLength = data.count
        let outLength = pixelCount * newComponents
        let bitDepth: UInt8 = UInt8(self.format.code.depth)
        
        switch self.format
        {
        case .v1, .v2, .v4:
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }

            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_v_to_rgba8(`in`, out, inLength, bitDepth, chromaKeyPointer)
            } else {
                convert_v_to_rgba8(`in`, out, inLength, bitDepth, nil)
            }
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .v8:
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_v8_to_rgba8(`in`, out, inLength, chromaKeyPointer)
            } else {
                convert_v8_to_rgba8(`in`, out, inLength, nil)
            }
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .v16:
            inLength = inLength / 2
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_v16_to_rgba8(`in`, out, inLength, chromaKeyPointer)
            } else {
                convert_v16_to_rgba8(`in`, out, inLength, nil)
            }
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .va8:
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            convert_va8_to_rgba8(`in`, out, inLength)
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .va16:
            inLength = inLength / 2
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            convert_va16_to_rgba8(`in`, out, inLength)
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .rgb8:
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_rgb8_to_rgba8(`in`, out, inLength, chromaKeyPointer)
            } else {
                convert_rgb8_to_rgba8(`in`, out, inLength, nil)
            }
           
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .rgb16:
            inLength = inLength / 2
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            if var chromaKey = self.chromaKey {
                let chromaKeyPointer = withUnsafePointer(to: &chromaKey) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: 4) {
                        $0
                    }
                }
                convert_rgb16_to_rgba8(`in`, out, inLength, chromaKeyPointer)
            } else {
                convert_rgb16_to_rgba8(`in`, out, inLength, nil)
            }
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case .rgba8:
            return data

        case .rgba16:
            inLength = inLength / 2
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            convert_rgba16_to_rgba8(`in`, out, inLength)
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        case    .indexed1(let palette),
                .indexed2(let palette),
                .indexed4(let palette):
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            convert_index_to_rgba8(`in`, out, inLength, bitDepth, palettePointer)
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            
            return Array(buffer)
            
        case    .indexed8(let palette):
            let `in` = data.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: inLength) {
                    $0
                }
            }
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
            memset(out, 0, outLength)
            defer {
                out.deallocate()
            }
            
            let palettePointer = palette.withUnsafeBufferPointer {
                $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: palette.count * 4) {
                    $0
                }
            }
            
            convert_index8_to_rgba8(`in`, out, inLength, bitDepth, palettePointer)
            
            let buffer = UnsafeMutableBufferPointer<UInt8>(start: out, count: outLength)
            return Array(buffer)
            
        }
    }
    /// 根据解码后的像素和fcTL创建帧/Create a frame based on the decoded pixels and FCTL
    ///
    /// - Parameters:
    ///   - fcTL: 帧控制chunk/frame control chunk
    ///   - rgba: 解码后的像素/decoded pixels
    ///   - buffer: 输出缓冲区，初始化为第一帧/Output buffer, initialized to the first frame
    /// - Returns: 可用于渲染的PNG/Can be used for rendering PNG image
    fileprivate func frame(fcTL: FrameControl, rgba: [UInt8], buffer: inout [UInt8]) -> Frame {
        
        let outputBufferWidth = Int(header.size.width)
        let frameWidth = Int(fcTL.width)
        let frameHeight = Int(fcTL.height)
        let xOffset = Int(fcTL.xOffset)
        let yOffset = Int(fcTL.yOffset)
      
        switch fcTL.blendOp {
        case .source: // 根据x, y偏移量替换输出缓冲区帧区域为当前帧像素/Replace the output buffer frame area with the x, y offset as the current frame pixel
            let rgba = rgba.withUnsafeBytes {
                $0.baseAddress!.assumingMemoryBound(to: RGBA<UInt8>.self)
            }
            
            let buffer = buffer.withUnsafeMutableBytes {
                $0.baseAddress!.assumingMemoryBound(to: RGBA<UInt8>.self)
            }
            
            for i in 0..<frameHeight {
                let start = (i + yOffset) * outputBufferWidth + xOffset
                for x in 0..<frameWidth {
                    buffer[start + x] = rgba[i * frameWidth + x]
                }
            }
        case .over: // alpha通道合成操作/Alpha channel synthesis operation
            let rgba = rgba.withUnsafeBytes {
                $0.baseAddress!.assumingMemoryBound(to: RGBA<UInt8>.self)
            }
            
            let buffer = buffer.withUnsafeMutableBytes {
                $0.baseAddress!.assumingMemoryBound(to: RGBA<UInt8>.self)
            }
            for i in 0..<frameHeight {
                let start = (i + yOffset) * outputBufferWidth + xOffset
                
                for x in 0..<frameWidth {
                    let foreground = rgba[i * frameWidth + x]
                    let background = buffer[start + x]
                    let ialpha = foreground.a
                    
                    if ialpha == 0 {
                        
                    } else if ialpha == 255 {
                        buffer[start + x] = RGBA(foreground.r, foreground.g, foreground.b, 255)
                    } else {
                        // display = sorce X alpha / 255 + background X (255 - alpha) / 255
                        let compR = foreground.r &* ialpha / 255 + background.r &* (255 - ialpha) / 255
                        let compG = foreground.g &* ialpha / 255 + background.g &* (255 - ialpha) / 255
                        let compB = foreground.b &* ialpha / 255 + background.b &* (255 - ialpha) / 255
                        let display = RGBA(compR, compG, compB)
                        buffer[start + x] = display
                    }
                }
            }
        }
        
        var png = defaultImage
        png.data = buffer
        let frame = Frame(frameControl: fcTL, png: png)
        
        switch fcTL.disposeOp {
        case .none: // 不处理输出缓冲区/Does not process the output buffe
            break
        case .background: // 根据x, y偏移量，替换输出缓冲区帧区域为黑色透明像素/Replace the output buffer frame area as a black transparent pixel based on the x, y offse
            let buffer = buffer.withUnsafeMutableBytes {
                $0.baseAddress!.assumingMemoryBound(to: RGBA<UInt8>.self)
            }
            for i in 0..<frameHeight {
                let start = (i + yOffset) * outputBufferWidth + xOffset
                let b = RGBA<UInt8>(0, 0, 0, 0)
                for x in 0..<frameWidth {
                    buffer[start + x] = b
                }
            }
        case .previous: // 恢复输出缓冲区为上一帧像素/Restore the output buffer to the previous frame of pixels
            if let lastFrame = frames.last {
                buffer = lastFrame.png.data
            }
        }
        
        return frame
    }
}
