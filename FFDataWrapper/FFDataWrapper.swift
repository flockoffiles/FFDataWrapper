//
//  FFDataWrapper.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

public typealias FFDataWrapperCoder = (UnsafePointer<UInt8>, Int, inout Data) -> Void

public struct FFDataWrapper
{
    internal class Deiniter
    {
        let dataPtr: UnsafeMutableRawPointer
        init(dataPtr: UnsafeMutableRawPointer)
        {
            self.dataPtr = dataPtr
        }
        
        deinit {
            let count = dataPtr.assumingMemoryBound(to: Data.self).pointee.count
            dataPtr.assumingMemoryBound(to: Data.self).pointee.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) in
                ptr.initialize(to: 0, count: count)
            }
        }
    }
    
    internal var data: Data
    internal let deiniter: Deiniter
    internal let encoder: FFDataWrapperCoder
    internal let decoder: FFDataWrapperCoder
    
    public init(_ string: String, coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder))
    {
        self.encoder = coders.encoder
        self.decoder = coders.decoder
        
        let utf8 = string.utf8CString
        let length = utf8.count
        data = Data(capacity: length)
        deiniter = Deiniter(dataPtr: { $0 as UnsafeMutableRawPointer }(&self.data))

        if (length > 0)
        {
            // Obfuscate the data
            utf8.withUnsafeBytes {
                coders.encoder($0.baseAddress!.assumingMemoryBound(to: UInt8.self), length, &data)
            }
        }
    }
    
    public init(_ string: String)
    {
        self.init(string, coders: FFDataWrapperEncoders.xorWithRandomVectorOfLength(string.utf8.count).coders)
    }
    
    public init(_ data: Data, coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder))
    {
        self.encoder = coders.encoder
        self.decoder = coders.decoder

        let length = data.count
        self.data = Data(capacity: length)
        deiniter = Deiniter(dataPtr: { $0 as UnsafeMutableRawPointer }(&self.data))
        if (length > 0)
        {
            // Obfuscate the data
            data.withUnsafeBytes {
                coders.encoder($0, length, &self.data)
            }
        }
    }

    public func withDecodedData(_ block: (inout Data) -> Void)
    {
        var decodedData = Data()
        let dataLength = data.count
        data.withUnsafeBytes {
            decoder($0, dataLength, &decodedData)
        }
        
        block(&decodedData)
        let decodedDataLength = decodedData.count
        decodedData.withUnsafeMutableBytes {
            $0.initialize(to: 0, count: decodedDataLength)
        }
    }
}

enum FFDataWrapperEncoders
{
    internal static func xorEncoderWithVector(_ vector: Data) -> FFDataWrapperCoder
    {
        return { (src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data) in
            xor(src: src, srcLength: srcLength, dest: &dest, with: vector)
        }
    }
    
    internal static func xorDecoderWithVector(_ vector: Data) -> FFDataWrapperCoder
    {
        return { (src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data) in
            xor(src: src, srcLength: srcLength, dest: &dest, with: vector)
        }
    }
    
    case xorWithRandomVectorOfLength(Int)
    
    var coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder) {
        switch self
        {
        case .xorWithRandomVectorOfLength(let length):
            var vector = Data(count: length)
            let _ = vector.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, length, $0)
            }
            
            return (encoder: FFDataWrapperEncoders.xorEncoderWithVector(vector), decoder: FFDataWrapperEncoders.xorDecoderWithVector(vector))
        }
    }
    
}

internal func xor(src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data, with: Data)
{
    guard srcLength > 0 && with.count > 0 else {
        return
    }
    
    let destLength = dest.count
    // Wipe contents if needed.
    if (destLength > 0)
    {
        dest.withUnsafeMutableBytes {
            $0.initialize(to: 0, count: destLength)
        }
    }
    
    if (destLength < srcLength)
    {
        dest.reserveCapacity(srcLength)
    }
    
    var j = 0
    for i in 0 ..< srcLength
    {
        dest[i] = src[i] ^ with[j]
        j += 1
        if j >= with.count
        {
            j = 0
        }
    }
}


