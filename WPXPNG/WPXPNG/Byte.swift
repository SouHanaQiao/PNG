//
//  Byte.swift
//  WPXPNG
//
//  Created by 葬花桥 on 2019/5/9.
//  Copyright © 2019 葬花桥. All rights reserved.
//

import zlib

extension WPX.PNG {
    public enum Bytes {
        public struct Source: DataSource {
            
            var data: [UInt8]
            
            private var index: Int = 0
            
            public init(data: [UInt8] = []) {
                self.data = data
            }
            
            public mutating func update(data: [UInt8]) {
                self.data.append(contentsOf: data)
            }
            
            public mutating func read(count: Int) -> [UInt8]? {
                guard data.count - index >= count else {
                    return nil
                }
                /// 使用指针大幅度提升性能
                //            return [UInt8](data[index..<index + count])
                
                let buffer = UnsafeMutableBufferPointer<UInt8>(start: &data + index, count: count)
                
                return Array(buffer)
            }
            
            public mutating func begin() throws
            {
                guard let bytes:[UInt8] = read(count: [137, 80, 78, 71, 13, 10, 26, 10].count),
                    bytes == [137, 80, 78, 71, 13, 10, 26, 10]
                    else
                {
                    throw WPX.PNG.DecodingError.missingSignature
                }
                index += 8
            }
            
            private var headerIndex = 8
            private var chunkDataIndex = 16
            
            public mutating
            func next() throws -> WPX.PNG.Chunk?
            {
                guard data.count - headerIndex >= 8 else {
                    return nil
                }
                
                let header = UnsafeMutableBufferPointer<UInt8>(start: &data + headerIndex, count: 8)
            
                let length = header.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                    $0.pointee.bigEndian
                }
               
                let name = (header[4], header[5], header[6], header[7])
                guard let tag: WPX.PNG.Chunk.Tag = WPX.PNG.Chunk.Tag(name)
                    else
                {
                    throw WPX.PNG.DecodingError.invalidName(name)
                }
                
                let chunkType = WPX.PNG.Chunk.ChunkType(tag)
                
                let count = min(data.count - chunkDataIndex, Int(length))
                
                // idAT count should > 0
                if length > 0, count == 0 {
                    return nil
                }
                
                let chunkData = UnsafeMutableBufferPointer<UInt8>(start: &data + chunkDataIndex, count: count)
                chunkDataIndex += count
                
                var checksum: UInt32 = 0
                if data.count - chunkDataIndex >=  4 {
                    
                    let testsum: UInt  = header.suffix(4).withUnsafeBufferPointer
                    {
                        return crc32(crc32(0, $0.baseAddress, 4), chunkData.baseAddress, length)
                    }
                    
                    let crc = UnsafeMutableBufferPointer<UInt8>(start: &data + chunkDataIndex, count: 4)
                    checksum = crc.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        $0.pointee.bigEndian
                    }
                    
                    guard testsum == checksum
                        else
                    {
                        throw WPX.PNG.DecodingError.corruptedChunk(chunkType)
                    }
                    
                    chunkDataIndex += 4 + 8
                    headerIndex += Int(length) + 4 + 8
                }
                
                return WPX.PNG.Chunk(length: length, chunkType: chunkType, chunkData: Array(chunkData), crc: UInt32(checksum))
            }
        }
    }
}

extension WPX.APNG {
    public enum Bytes {
        public struct Source: DataSource {
            
            var data: [UInt8]
            
            private var index: Int = 0
            
            public init(data: [UInt8] = []) {
                self.data = data
            }
            
            public mutating func update(data: [UInt8]) {
                self.data.append(contentsOf: data)
            }
            
            public mutating func read(count: Int) -> [UInt8]? {
                guard data.count - index >= count else {
                    return nil
                }
                /// 使用指针大幅度提升性能
                //            return [UInt8](data[index..<index + count])
                
                let buffer = UnsafeMutableBufferPointer<UInt8>(start: &data + index, count: count)
                
                return Array(buffer)
            }
            
            public mutating func begin() throws
            {
                guard let bytes:[UInt8] = read(count: [137, 80, 78, 71, 13, 10, 26, 10].count),
                    bytes == [137, 80, 78, 71, 13, 10, 26, 10]
                    else
                {
                    throw WPX.APNG.DecodingError.missingSignature
                }
            }
            
            private var headerIndex = 8
            private var chunkDataIndex = 16
            
            public mutating
            func next() throws -> Chunk?
            {
                guard data.count - headerIndex >= 8 else {
                    return nil
                }
                
                let header = UnsafeMutableBufferPointer<UInt8>(start: &data + headerIndex, count: 8)
                
                let length = header.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                    $0.pointee.bigEndian
                }
                
                let name = (header[4], header[5], header[6], header[7])
                guard let tag: Chunk.Tag = Chunk.Tag(name)
                    else
                {
                    throw DecodingError.invalidName(name)
                }
                
                let chunkType = Chunk.ChunkType(tag)
                
                let count = min(data.count - chunkDataIndex, Int(length))
                
                // idAT count should > 0
                if length > 0, count == 0 {
                    return nil
                }
                
                let chunkData = UnsafeMutableBufferPointer<UInt8>(start: &data + chunkDataIndex, count: count)
                chunkDataIndex += count
                
                var checksum: UInt32 = 0
                if data.count - chunkDataIndex >=  4 {
                    
                    let testsum: UInt  = header.suffix(4).withUnsafeBufferPointer
                    {
                        return crc32(crc32(0, $0.baseAddress, 4), chunkData.baseAddress, length)
                    }
                    
                    let crc = UnsafeMutableBufferPointer<UInt8>(start: &data + chunkDataIndex, count: 4)
                    checksum = crc.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) {
                        $0.pointee.bigEndian
                    }
                    
                    guard testsum == checksum
                        else
                    {
                        throw DecodingError.corruptedChunk(chunkType)
                    }
                    
                    chunkDataIndex += 4 + 8
                    headerIndex += Int(length) + 4 + 8
                }
                
                return Chunk(length: length, chunkType: chunkType, chunkData: Array(chunkData), crc: UInt32(checksum))
            }
        }
    }
}
