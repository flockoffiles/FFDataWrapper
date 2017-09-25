//
//  FFDataWrapper.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

public typealias FFDataWrapperCoder = (UnsafePointer<UInt8>, Int, inout Data) -> Void

/// FFDataWrapper is a struct which wraps a piece of data and provides some custom internal representation for it.
/// Conversions between original and internal representations can be specified with encoder and decoder closures.
public struct FFDataWrapper
{
    /// Helper class which makes sure that the internal representation gets wiped securely when FFDataWrapper is destroyed.
    internal class Deiniter
    {
        /// Pointer to the data buffer holding the internal representation of the wrapper data.
        /// Here we rely on the fact that the data container for the internal representation is Swift Data (see below).
        let dataPtr: UnsafeMutableRawPointer
        
        init(dataPtr: UnsafeMutableRawPointer)
        {
            print("Data ptr = \(dataPtr)")
            self.dataPtr = dataPtr
        }
        
        deinit
        {
//            let d = dataPtr.assumingMemoryBound(to: Data.self).pointee
//            let count = dataPtr.assumingMemoryBound(to: Data.self).pointee.count
//            // Wipe all the bytes held by the internal buffer.
//            dataPtr.assumingMemoryBound(to: Data.self).pointee.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<UInt8>) in
//                ptr.initialize(to: 0, count: count)
//            }
        }
    }
    
    /// Closure to convert external representation to internal.
    internal let encoder: FFDataWrapperCoder
    
    /// Closure to convert internal representation to external.
    internal let decoder: FFDataWrapperCoder

    /// Data container holding the internal representation of the wrapped data.
    internal var data: Data

    /// Class responsible for wiping the data buffer when FFDataWrapper is destroyed.
    internal let deiniter: Deiniter
    

    
    /// Initialize the data wrapper with the given string content and a pair of coder/decoder to convert between representations.
    ///
    /// - Parameters:
    ///   - string: The string data to wrap. The string gets converted to UTF8 data before being fed to the encoder closure.
    ///   - coders: The encoder/decoder pair which performs the conversion between external and internal representations.
    public init(_ string: String, coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder))
    {
        self.encoder = coders.encoder
        self.decoder = coders.decoder
        
        let utf8 = string.utf8CString
        let length = string.lengthOfBytes(using: .utf8) // utf8.count also accounts for the last 0 byte.
        
        data = Data(capacity: length)
        /// We provide the start address of data to the Deiniter.
        /// Here we assume that the address of data never changes while FFDataWrapper struct is alive.
        /// (Also see: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/Data.swift)
        deiniter = Deiniter(dataPtr: { $0 as UnsafeMutableRawPointer }(&self.data))

        // If length is 0 there may not be a pointer to the string content
        if (length > 0)
        {
            // Obfuscate the data
            utf8.withUnsafeBytes {
                coders.encoder($0.baseAddress!.assumingMemoryBound(to: UInt8.self), length, &data)
            }
        }
        else
        {
            // This is the case of an empty string. We still want to call in encoder for the case
            // where the encoder wants to represent empty content with some non-empty encoded content
            // (e.g. in order to hide the fact that the content is empty)
            // Allocate 1 byte of data, just to get a non-nil pointer.
            let emptyDataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
            // We still specify a zero length to the encoder.
            coders.encoder(emptyDataPtr, 0, &data)
            // Get rid of the memory.
            emptyDataPtr.deallocate(capacity: 1)
        }

        // let d = deiniter.dataPtr.assumingMemoryBound(to: Data.self).pointee

    }
    
    
    /// Create a wrapper with the given string content and use the XOR transformation for internal representation.
    /// (Good for simply obfuscation).
    /// - Parameter string: The string data to wrap.
    public init(_ string: String)
    {
        self.init(string, coders: FFDataWrapperEncoders.xorWithRandomVectorOfLength(string.utf8.count).coders)
    }
    
    
    /// Create a wrapper with the given data content and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameters:
    ///   - data: The data to wrap.
    ///   - coders: Pair of coders to use to convert to/from the internal representation.
    public init(_ data: Data, coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder))
    {
        self.encoder = coders.encoder
        self.decoder = coders.decoder

        let length = data.count
        self.data = Data(capacity: length)
        deiniter = Deiniter(dataPtr: { $0 as UnsafeMutableRawPointer }(&self.data))
        if (length > 0)
        {
            // Encode the data
            data.withUnsafeBytes {
                coders.encoder($0, length, &self.data)
            }
        }
    }

    
    /// Execute the given closure with wrapped data.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    ///
    /// - Parameter block: The closure to execute.
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

/// Enumeration defining some basic coders (transformers)
public enum FFDataWrapperEncoders
{
    /// Do not transform. Just copy.
    case identity
    /// XOR with the random vector of the given legth.
    case xorWithRandomVectorOfLength(Int)
    
    var coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder) {
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
    
    internal static func xorWithVector(_ vector: Data) -> FFDataWrapperCoder
    {
        return { (src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data) in
            xor(src: src, srcLength: srcLength, dest: &dest, with: vector)
        }
    }
    
    internal static func identityFunction() -> FFDataWrapperCoder
    {
        return { (src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data) in
            justCopy(src: src, srcLength: srcLength, dest: &dest)
        }
    }
}


/// Simple identity transformation.
///
/// - Parameters:
///   - src: Source data to transform.
///   - srcLength: Length of the source data.
///   - dest: Destination data buffer. Will be cleared before transformation takes place.
internal func justCopy(src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data)
{
    let destLength = dest.count
    // Wipe contents if needed.
    if (destLength > 0)
    {
        dest.withUnsafeMutableBytes {
            $0.initialize(to: 0, count: destLength)
        }
        dest.removeAll()
    }

    guard srcLength > 0 else {
        return
    }

    if (destLength < srcLength)
    {
        // This may cause buffer reallocation.
        dest.reserveCapacity(srcLength)
    } // Otherwise we already have the needed capacity.

    dest.append(src, count: srcLength)
}

/// Sample transformation for custom content. XORs the source representation (byte by byte) with the given vector.
///
/// - Parameters:
///   - src: Source data to transform.
///   - srcLength: Length of the source data.
///   - dest: Destination data buffer. Will be cleared before transformation takes place.
///   - with: Vector to XOR with. If the vector is shorter than the original data, it will be wrapped around.
internal func xor(src: UnsafePointer<UInt8>, srcLength: Int, dest: inout Data, with: Data)
{
    let destLength = dest.count

    // Initialize contents
    if (destLength > 0)
    {
        dest.withUnsafeMutableBytes {
            $0.initialize(to: 0, count: destLength)
        }
        dest.removeAll()
    }
    
    guard srcLength > 0 && with.count > 0 else {
        return
    }
    
    
    if (destLength < srcLength)
    {
        // This may cause buffer reallocation.
        dest.reserveCapacity(srcLength)
    } // Otherwise we already have the needed capacity.
    
    var j = 0
    for i in 0 ..< srcLength
    {
        dest.append(src[i] ^ with[j])
        j += 1
        if j >= with.count
        {
            j = 0
        }
    }
}


