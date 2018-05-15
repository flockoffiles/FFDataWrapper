//
//  FFDataWrapperEncoders.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 26/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

/// Enumeration defining some basic coders (transformers)
public enum FFDataWrapperEncoders
{
    /// Do not transform. Just copy.
    case identity
    /// XOR with the random vector of the given legth.
    case xorWithRandomVectorOfLength(Int)
    
    public var coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder) {
        switch self
        {
        case .identity:
            return (encoder: FFDataWrapperEncoders.identityFunction(), FFDataWrapperEncoders.identityFunction())
        case .xorWithRandomVectorOfLength(let length):
            var vector = Data(count: length)
            let _ = vector.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, length, $0)
            }
            
            return (encoder: FFDataWrapperEncoders.xorWithVector(vector), decoder: FFDataWrapperEncoders.xorWithVector(vector))
        }
    }
    
    public static func xorWithVector(_ vector: Data) -> FFDataWrapperCoder
    {
        return { (src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>) in
            xor(src: src, dest: dest, with: vector)
        }
    }
    
    public static func identityFunction() -> FFDataWrapperCoder
    {
        return { (src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>) in
            justCopy(src: src, dest: dest)
        }
    }
}

public extension FFDataWrapperEncoders
{
    /// Simple identity transformation.
    ///
    /// - Parameters:
    ///   - src: Source data to transform.
    ///   - srcLength: Length of the source data.
    ///   - dest: Destination data buffer. Will be cleared before transformation takes place.
    public static func justCopy(src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>)
    {
        // Wipe contents if needed.
        if (dest.count > 0)
        {
            dest.baseAddress!.initialize(repeating: 0, count: dest.count)
        }
        
        guard src.count > 0 && dest.count >= src.count else {
            return
        }

        dest.baseAddress!.assign(from: src.baseAddress!, count: src.count)
    }
    

    
    /// Sample transformation for custom content. XORs the source representation (byte by byte) with the given vector.
    ///
    /// - Parameters:
    ///   - src: Source data to transform.
    ///   - dest: Destination data buffer. Will be cleared before transformation takes place.
    ///   - with: Vector to XOR with. If the vector is shorter than the original data, it will be wrapped around.
    public static func xor(src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>, with: Data)
    {
        // Initialize contents
        if (dest.count > 0)
        {
            dest.baseAddress!.initialize(repeating: 0, count: dest.count)
        }
        
        guard src.count > 0 && dest.count >= src.count else {
            return
        }
        
        var j = 0
        for i in 0 ..< dest.count
        {
            let srcByte: UInt8 = i < src.count ? src[i] : 0
            dest[i] = srcByte ^ with[j]
            j += 1
            if j >= with.count
            {
                j = 0
            }
        }
    }
}
