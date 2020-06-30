//
//  LZ77.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/9.
//  Copyright © 2019 葬花桥. All rights reserved.
//

import zlib

protocol LZ77Stream
{
    var stream:UnsafeMutablePointer<z_stream>
    {
        get
        set
    }
    
    var input:[UInt8]
    {
        get
        set
    }
}

extension LZ77Stream
{
    func destroyStream(deinitializingWith deinitializer:(UnsafeMutablePointer<z_stream>) -> Int32)
    {
        guard deinitializer(self.stream) == Z_OK
            else
        {
            fatalError("failed to deinitialize `z_stream` structure")
        }
        
        self.stream.deinitialize(count: 1)
        self.stream.deallocate()
    }
    
    var unprocessedCount:Int
    {
        get
        {
            return .init(self.stream.pointee.avail_in)
        }
        set(value)
        {
            self.stream.pointee.avail_in = .init(value)
        }
    }
    
    fileprivate
    func check(status:Int32) throws -> Bool
    {
        switch status
        {
        case Z_STREAM_END:
            return false
            
        case Z_OK,
             Z_BUF_ERROR:
            return true
            
        case Z_NEED_DICT:
            throw WPX.PNG.LZ77.Error.missingDictionary
            
        case Z_DATA_ERROR:
            throw WPX.PNG.LZ77.Error.data
            
        case Z_MEM_ERROR:
            throw WPX.PNG.LZ77.Error.memory
            
        case Z_STREAM_ERROR:
            fatalError("deflate(_:_:) was called on \(Self.self) stream after having been passed Z_FINISH without being passed Z_FINISH")
            
        default:
            fatalError("unreachable error \(status)")
        }
    }
    
    // used to test for Z_STREAM_END. THIS FUNCTION CLOBBERS THE LZ77 STREAM.
    // ONLY CALL IT IF YOU EXPECT THE RESULT TO BE `false`
    func test(_ body:(UnsafeMutablePointer<z_stream>) -> Int32) throws -> Bool
    {
        var _bait:UInt8  = .init()
        let status:Int32 = withUnsafeMutablePointer(to: &_bait)
        {
            
            self.stream.pointee.next_out  = $0
            self.stream.pointee.avail_out = 1
            return self.input.withUnsafeBufferPointer
                {
                    let offset:Int              = self.input.count - self.unprocessedCount
                    self.stream.pointee.next_in = $0.baseAddress.map{ .init(mutating: $0 + offset) }
                    
                    return body(self.stream)
                    
            }
        }
        
        return try self.check(status: status)
    }
}

extension WPX.PNG {
    /// A namespace for LZ77 utilities. Not for public use.
    public
    enum LZ77
    {
        /// Errors that can occur in the LZ77 compression or decompression process.
        public
        enum Error:Swift.Error
        {
            /// A zlib stream object failed to initialize properly.
            case initialization
            /// The `Z_NEED_DICT` error occured.
            case missingDictionary
            /// The `Z_DATA_ERROR` error occured.
            case data
            /// The `Z_MEM_ERROR` error occured.
            case memory
        }
        
        class Deflator: LZ77Stream
        {
            var stream:UnsafeMutablePointer<z_stream>,
            input:[UInt8] = []
            
            init(level: Int) throws
            {
                precondition(0 ..< 10 ~= level)
                stream = .allocate(capacity: 1)
                stream.initialize(to:  .init(next_in: nil,
                                             avail_in: 0,
                                             total_in: 0,
                                             next_out: nil,
                                             avail_out: 0,
                                             total_out: 0,
                                             msg: nil,
                                             state: nil,
                                             
                                             zalloc: nil,
                                             zfree: nil,
                                             opaque: nil,
                                             
                                             data_type: 0,
                                             adler: 0,
                                             reserved: 0))
                
                let status: Int32 = deflateInit_(stream, Int32(level), ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                if status != Z_OK {
                    stream.deinitialize(count: 1)
                    stream.deallocate()
                    throw Error.initialization
                }
            }
            
            deinit
            {
                self.destroyStream(deinitializingWith: deflateEnd(_:))
            }
            
            func push(input: [UInt8]) {
                self.input.append(contentsOf: input)
            }
            
            func pull() throws -> [UInt8] {
                var status: Int32 = 0
                let aval_in = self.input.count
                self.stream.pointee.next_in = self.input.withUnsafeMutableBytes {
                    $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
                self.stream.pointee.avail_in = .init(aval_in)
                
                let bound = deflateBound(stream, .init(aval_in))
                let aval_out = Int(bound)
                let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: aval_out)
                defer {
                    outputBuffer.deallocate()
                }
                
                stream.pointee.next_out = outputBuffer
                stream.pointee.avail_out = .init(aval_out)
                status = deflate(stream, Z_FINISH)
                
//                while deflate(stream, Z_FINISH) != Z_STREAM_END {
//                    stream.pointee.next_out = outputBuffer + .init(stream.pointee.total_out)
//                    stream.pointee.avail_out = uInt(.init(aval_out) - stream.pointee.total_out)
//                }
                
                _ = try self.check(status: status)
                let buffer = UnsafeMutableBufferPointer<UInt8>(start: outputBuffer, count: .init(stream.pointee.total_out))
                
                return Array(buffer)
            }
        }
        
        class Inflator: LZ77Stream
        {
            var stream:UnsafeMutablePointer<z_stream>,
            input:[UInt8] = []
            var output: UnsafeMutablePointer<UInt8>
            var avail_out: Int = 0
            var outputOffset: Int = 0
            
            var totalOut: Int {
                return Int(stream.pointee.total_out)
            }
            
            init(isApplePNG: Bool = false, outBufferCapacity: Int) throws
            {
                avail_out = outBufferCapacity
                output = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufferCapacity)
                stream = .allocate(capacity: 1)
                stream.initialize(to:  .init(next_in: nil,
                                             avail_in: 0,
                                             total_in: 0,
                                             next_out: output,
                                             avail_out: 0,
                                             total_out: 0,
                                             msg: nil,
                                             state: nil,
                                             
                                             zalloc: nil,
                                             zfree: nil,
                                             opaque: nil,
                                             
                                             data_type: 0,
                                             adler: 0,
                                             reserved: 0))
                
                let status: Int32
                if isApplePNG {
                    status = inflateInit2_(stream, -15, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                } else {
                    status = inflateInit_(stream, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
                }
                if status != Z_OK {
                    stream.deinitialize(count: 1)
                    stream.deallocate()
                    throw Error.initialization
                }
            }
            
            deinit
            {
                self.destroyStream(deinitializingWith: inflateEnd(_:))
                output.deallocate()
            }
            
            func push(input: [UInt8]) throws -> Bool {
                self.input = input
                self.stream.pointee.next_in = self.input.withUnsafeMutableBytes {
                    $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
                self.stream.pointee.avail_in = .init(input.count)
                
                stream.pointee.avail_out = uInt(avail_out - Int(stream.pointee.total_out))
                
                
                let status = inflate(stream, Z_NO_FLUSH)
                
                switch status
                {
                case Z_STREAM_END:
                    return false
                    
                case Z_OK,
                     Z_BUF_ERROR:
                    return stream.pointee.avail_out != 0
                    
                case Z_NEED_DICT:
                    throw Error.missingDictionary
                    
                case Z_DATA_ERROR:
                    throw Error.data
                    
                case Z_MEM_ERROR:
                    throw Error.memory
                    
                case Z_STREAM_ERROR:
                    fatalError("deflate(_:_:) was called on \(self.self) stream after having been passed Z_FINISH without being passed Z_FINISH")
                    
                default:
                    fatalError("unreachable error \(status)")
                }
            }
            
            func scanline(lineCount: Int) -> UnsafeMutablePointer<UInt8>? {
                
                if Int(stream.pointee.total_out) - outputOffset >= lineCount {
                    defer {
                        outputOffset += lineCount
                    }
                    return output + outputOffset
                }
                
                return nil
            }
            
            func test() throws -> Bool
            {
                return try self.test
                    {
                        inflate($0, Z_NO_FLUSH)
                }
            }
        }
    }
}
