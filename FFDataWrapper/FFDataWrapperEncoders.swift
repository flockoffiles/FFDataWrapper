//
//  FFDataWrapperEncoders.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 26/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

/// Enumeration defining some basic coders (transformers)
public enum FFDataWrapperEncoders {
    /// Do not transform. Just copy.
    case identity
    /// XOR with the random vector of the given legth.
    case xorWithRandomVectorOfLength(Int)
    /// XOR with the given vector
    case xor(Data)
    
    public var coders: FFDataWrapper.Coders {
        switch self {
        case .identity:
            return (encoder: FFDataWrapperEncoders.identityFunction(), decoder: FFDataWrapperEncoders.identityFunction())
        case .xorWithRandomVectorOfLength(let length):
            var vector = Data(count: length)
            let _ = vector.withUnsafeMutableBytes {
                return SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!)
            }
            
            return (encoder: FFDataWrapperEncoders.xorWithVector(vector), decoder: FFDataWrapperEncoders.xorWithVector(vector))
        case .xor(let vector):
            return (encoder: FFDataWrapperEncoders.xorWithVector(vector), decoder: FFDataWrapperEncoders.xorWithVector(vector))
        }
    }
    
    public var infoCoders: FFDataWrapper.InfoCoders {
        switch self {
        case .identity:
            return (encoder: FFDataWrapperEncoders.infoIdentityFunction(), decoder: FFDataWrapperEncoders.infoIdentityFunction())
        case .xorWithRandomVectorOfLength(let length):
            var vector = Data(count: length)
            let _ = vector.withUnsafeMutableBytes {
                return SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!)
            }
            
            return (encoder: FFDataWrapperEncoders.infoXorWithVector(vector), decoder: FFDataWrapperEncoders.infoXorWithVector(vector))
        case .xor(let vector):
            return (encoder: FFDataWrapperEncoders.infoXorWithVector(vector), decoder: FFDataWrapperEncoders.infoXorWithVector(vector))
        }
    }
    
    public static func xorWithVector(_ vector: Data) -> FFDataWrapper.Coder {
        return { (src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>) in
            xor(src: src, dest: dest, with: vector)
        }
    }
    
    public static func infoXorWithVector(_ vector: Data) -> FFDataWrapper.InfoCoder {
        return { (src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>, info: Any?) in
            xor(src: src, dest: dest, with: vector)
        }
    }
    
    public static func identityFunction() -> FFDataWrapper.Coder {
        return { (src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>) in
            justCopy(src: src, dest: dest)
        }
    }
    
    public static func infoIdentityFunction() -> FFDataWrapper.InfoCoder {
        return { (src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>, info: Any?) in
            justCopy(src: src, dest: dest)
        }
    }
}

public extension FFDataWrapperEncoders {
    /// Simple identity transformation.
    ///
    /// - Parameters:
    ///   - src: Source data to transform.
    ///   - srcLength: Length of the source data.
    ///   - dest: Destination data buffer. Will be cleared before transformation takes place.
    static func justCopy(src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>) {
        // Wipe contents if needed.
        if (dest.count > 0) {
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
    static func xor(src: UnsafeBufferPointer<UInt8>, dest: UnsafeMutableBufferPointer<UInt8>, with: Data) {
        // Initialize contents
        if (dest.count > 0) {
            dest.baseAddress!.initialize(repeating: 0, count: dest.count)
        }
        
        guard src.count > 0 && dest.count >= src.count else {
            return
        }
        
        var j = 0
        for i in 0 ..< dest.count {
            let srcByte: UInt8 = i < src.count ? src[i] : 0
            dest[i] = srcByte ^ with[j]
            j += 1
            if j >= with.count {
                j = 0
            }
        }
    }
}

public extension Array where Element == UInt8 {
    func coders(_ coder: (Data) -> FFDataWrapper.Coder) -> (FFDataWrapper.Coder, FFDataWrapper.Coder) {
        let data = Data(self)
        return (coder(data), coder(data))
    }
}
