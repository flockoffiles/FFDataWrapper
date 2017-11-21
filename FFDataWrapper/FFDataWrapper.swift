//
//  FFDataWrapper.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

public typealias FFDataWrapperCoder = (UnsafeBufferPointer<UInt8>, UnsafeMutableBufferPointer<UInt8>) -> Void

/// FFDataWrapper is a struct which wraps a piece of data and provides some custom internal representation for it.
/// Conversions between original and internal representations can be specified with encoder and decoder closures.
public struct FFDataWrapper
{
    /// Class holding the data buffer and responsible for wiping the data when FFDataWrapper is destroyed.
    internal let dataRef: FFDataRef
    
    /// Closures to convert external representation to internal and back
    internal let coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)
    
    /// Initialize the data wrapper with the given string content and a pair of coder/decoder to convert between representations.
    ///
    /// - Parameters:
    ///   - string: The string data to wrap. The string gets converted to UTF8 data before being fed to the encoder closure.
    ///   - coders: The encoder/decoder pair which performs the conversion between external and internal representations. If nil, the default XOR coders will be used.
    public init(_ string: String, _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil)
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
                self.coders.encoder(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: UInt8.self), count:length),
                                    UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count:length))
            }
        }
    }
    
    /// Create a wrapper with the given data content and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameters:
    ///   - data: The data to wrap.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    public init(_ data: Data, _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil)
    {
        self.coders = coders ?? FFDataWrapperEncoders.xorWithRandomVectorOfLength(data.count).coders

        dataRef = FFDataRef(length: data.count)
        
        if (data.count > 0)
        {
            // Encode the data
            data.withUnsafeBytes {
                self.coders.encoder(UnsafeBufferPointer(start: $0, count: data.count),
                                    UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count))
            }
        }
    }
    
    
    /// Create a wrapper with the given length and the given initializer closure.
    ///
    /// - Parameters:
    ///   - length: The desired length.
    ///   - initializer: Initializer closure to set initial contents.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    public init(length: Int,
                _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil,
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
        self.coders.encoder(UnsafeBufferPointer(start: tempBufferPtr, count: length),
                            UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: length))

    }

    
    public init(capacity: Int,
                _ coders: (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)? = nil,
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
        self.coders.encoder(UnsafeBufferPointer(start: tempBufferPtr, count: actualLength),
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

    
    /// Execute the given closure with wrapped data.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    /// Wiping of the data will succeed ONLY if the data is not passed outside the closure (i.e. if there are no additional references to it
    /// by the time the closure completes).
    /// - Parameter block: The closure to execute.
    @discardableResult
    public func withDecodedData<ResultType>(_ block: (inout Data) throws -> ResultType) rethrows -> ResultType
    {
        var decodedData = Data(repeating:0, count: dataRef.dataBuffer.count)

        decodedData.withUnsafeMutableBytes({ (destPtr: UnsafeMutablePointer<UInt8>) -> Void in
            self.coders.decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                                UnsafeMutableBufferPointer(start: destPtr, count: dataRef.dataBuffer.count))
        })
        
        let result = try block(&decodedData)
        
        decodedData.resetBytes(in: 0 ..< decodedData.count)
        
        return result
    }
    
    
    /// Returns true if the wrapped data is empty; false otherwise.
    public var isEmpty: Bool
    {
        return dataRef.dataBuffer.count == 0
    }
    
    /// Returns the length of the underlying data
    public var length: Int
    {
        return dataRef.dataBuffer.count
    }
}

/// Perform the given closure on the underlying data of two wrappers.
///
/// - Parameters:
///   - w1: First wrapper
///   - w2: Second wrapper
///   - block: The closure to perform on the underlying data of two wrappers.
/// - Returns: Parametrized.
/// - Throws: Will only throw if the provided closure throws.
@discardableResult
public func withDecodedData<ResultType>(_ w1: FFDataWrapper,
                                        _ w2: FFDataWrapper,
                                        _ block: (inout Data, inout Data) throws -> ResultType) rethrows -> ResultType
{
    return try w1.withDecodedData({ (w1Data: inout Data) -> ResultType in
        return try w2.withDecodedData({ (w2Data: inout Data) -> ResultType in
            return try block(&w1Data, &w2Data)
        })
    })
}

extension FFDataWrapper: CustomStringConvertible
{
    public static func hexString(_ data: Data) -> String
    {
        var result = String()
        result.reserveCapacity(data.count * 2)
        for i in 0 ..< data.count
        {
            result += String(format: "%02X", data[i])
        }
        return result
    }

    func underlyingDataString() -> String
    {
        return self.withDecodedData { decodedData -> String in
            if let dataAsString = String(data: decodedData, encoding: .utf8)
            {
                return dataAsString
            }
            return FFDataWrapper.hexString(decodedData)
        }
    }
    
    public var description: String {
        return "FFDataWrapper: \(underlyingDataString())"
    }
}

extension FFDataWrapper: CustomDebugStringConvertible
{
    public var debugDescription: String {
        var result = "FFDataWrapper:\n"
        result += "Underlying data: \"\(underlyingDataString())\"\n"
        result += "dataRef: \(String(reflecting:dataRef))\n"
        result += "encoder: \(String(reflecting:self.coders.encoder))\n"
        result += "decoder: \(String(reflecting:self.coders.decoder))"
        return result
    }
}

extension FFDataWrapper: CustomPlaygroundQuickLookable
{
    public var customPlaygroundQuickLook: PlaygroundQuickLook
    {
        return .text(self.description)
    }
}



