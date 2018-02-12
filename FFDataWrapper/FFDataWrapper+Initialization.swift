//
//  FFDataWrapper+Initialization.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 09/02/2018.
//  Copyright © 2018 Flock of Files. All rights reserved.
//

import Foundation

public extension FFDataWrapper
{
    /// Initialize the data wrapper with the given string content and a pair of coder/decoder to convert between representations.
    ///
    /// - Parameters:
    ///   - string: The string data to wrap. The string gets converted to UTF8 data before being fed to the encoder closure.
    ///   - coders: The encoder/decoder pair which performs the conversion between external and internal representations. If nil, the default XOR coders will be used.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    public init(_ string: String,
                _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil,
                _ encode: Bool = true)
    {
        self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(string.utf8.count).coders
        
        let utf8 = string.utf8CString
        let length = string.lengthOfBytes(using: .utf8) // utf8.count also accounts for the last 0 byte.
        
        self.dataRef = FFDataRef(length: length)
        
        // If length is 0 there may not be a pointer to the string content
        if (length > 0)
        {
            // Obfuscate the data
            utf8.withUnsafeBytes {
                let encoder = encode ? self.coders.encoder : FFDataWrapperEncoders.identity.coders.encoder
                encoder(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: UInt8.self), count:length),
                        UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count:length))
            }
        }
    }
    
    /// Create a wrapper with the given data content and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameters:
    ///   - data: The data to wrap.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    public init(_ data: Data,
                _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil,
                _ encode: Bool = true)
    {
        self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(data.count).coders
        
        dataRef = FFDataRef(length: data.count)
        
        if (data.count > 0)
        {
            // Encode the data
            data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
                let encoder = encode ? self.coders.encoder : FFDataWrapperEncoders.identity.coders.encoder
                encoder(UnsafeBufferPointer(start: bytes, count: data.count),
                                    UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count))
            }
        }
    }
    
    /// Create a wrapper with the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil,
                _ encode: Bool = true,
                _ initializer: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows
    {
        guard length > 0 else {
            self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(0).coders
            self.dataRef = FFDataRef(length: 0)
            return
        }
        self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(length).coders
        self.dataRef = FFDataRef(length: length)
        
        let tempBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer {
            tempBufferPtr.initialize(to: 0, count: length)
            tempBufferPtr.deallocate(capacity: length)
        }
        
        try initializer(UnsafeMutableBufferPointer(start: tempBufferPtr, count: length))
        let encoder = encode ? self.coders.encoder : FFDataWrapperEncoders.identity.coders.encoder
        encoder(UnsafeBufferPointer(start: tempBufferPtr, count: length),
                UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: length))
    }
    
    
    /// Create a wrapper with the given maximum capacity (in bytes).
    ///
    /// - Parameters:
    ///   - capacity: The desired capacity (in bytes)
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to create initial data contents. The size of created data can be smaller (but never greater)
    ///                  than the capacity. The initializer closure must return the actual length of the data in its second parameter.
    /// - Throws: Error if capacity is >= 0 or if the actual length turns out to exceed the capacity.
    public init(capacity: Int,
                _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil,
                _ encode: Bool = true,
                _ initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) throws -> Void) rethrows
    {
        guard capacity > 0 else {
            self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(0).coders
            self.dataRef = FFDataRef(length: 0)
            return
        }
        
        let tempBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        
        defer {
            // Securely wipe the temp buffer.
            tempBufferPtr.initialize(to: 0, count: capacity)
            tempBufferPtr.deallocate(capacity: capacity)
        }
        
        var actualLength = capacity
        try initializer(UnsafeMutableBufferPointer(start: tempBufferPtr, count: capacity), &actualLength)
        
        guard actualLength > 0 && actualLength <= capacity else {
            self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(1).coders
            self.dataRef = FFDataRef(length: 0)
            return
        }
        
        self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(actualLength).coders
        self.dataRef = FFDataRef(length: actualLength)
        let encoder = encode ? self.coders.encoder : FFDataWrapperEncoders.identity.coders.encoder
        encoder(UnsafeBufferPointer(start: tempBufferPtr, count: actualLength),
                UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count))
        
    }
    
    /// Create a wrapper for an empty data value and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameter coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    public init(_ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil)
    {
        self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(0).coders
        dataRef = FFDataRef(length: 0)
    }
    
    /// Create a wrapper for an empty value and use the XOR transformation for internal representation (not really applied, just for consistency reasons).
    public init()
    {
        self.init(nil)
    }
}

