//
//  FFDataWrapper.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

public typealias FFDataWrapperCoder = (UnsafePointer<UInt8>, Int, UnsafeMutablePointer<UInt8>, Int) -> Void

/// FFDataWrapper is a struct which wraps a piece of data and provides some custom internal representation for it.
/// Conversions between original and internal representations can be specified with encoder and decoder closures.
public struct FFDataWrapper
{
    /// Helper class which makes sure that the internal representation gets wiped securely when FFDataWrapper is destroyed.
    internal class DataRef
    {
        /// Pointer to the data buffer holding the internal representation of the wrapper data.
        var dataBuffer: UnsafeMutablePointer<UInt8>
        var length: Int
        
        /// Create a buffer holder with the given initialized buffer.
        ///
        /// - Parameters:
        ///   - dataBuffer: The relevant data buffer.
        ///   - length: Actual buffer length.
        init(dataBuffer: UnsafeMutablePointer<UInt8>, length: Int)
        {
            self.dataBuffer = dataBuffer
            self.length = length
        }
        
        deinit
        {
            dataBuffer.initialize(to: 0, count: length)
            dataBuffer.deallocate(capacity: length)
        }
    }
    
    /// Closure to convert external representation to internal.
    internal let encoder: FFDataWrapperCoder
    
    /// Closure to convert internal representation to external.
    internal let decoder: FFDataWrapperCoder
    
    /// Class holding the data buffer and responsible for wiping the data when FFDataWrapper is destroyed.
    internal let dataRef: DataRef
    
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

        let bufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        dataRef = DataRef(dataBuffer: bufferPtr, length: length)
        
        // If length is 0 there may not be a pointer to the string content
        if (length > 0)
        {
            // Obfuscate the data
            utf8.withUnsafeBytes {
                coders.encoder($0.baseAddress!.assumingMemoryBound(to: UInt8.self), length, self.dataRef.dataBuffer, length)
            }
        }
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
        let bufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        dataRef = DataRef(dataBuffer: bufferPtr, length: length)
        
        if (length > 0)
        {
            // Encode the data
            data.withUnsafeBytes {
                coders.encoder($0, length, self.dataRef.dataBuffer, length)
            }
        }
    }

    
    /// Execute the given closure with wrapped data.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    ///
    /// - Parameter block: The closure to execute.
    public func withDecodedData(_ block: (inout Data) -> Void)
    {
        let dataLength = dataRef.length
        var decodedData = Data(repeating:0, count: dataLength)

        decodedData.withUnsafeMutableBytes({ (destPtr: UnsafeMutablePointer<UInt8>) -> Void in
            decoder(dataRef.dataBuffer, dataLength, destPtr, dataLength)
        })
        
        block(&decodedData)
        
        let decodedDataLength = decodedData.count
        decodedData.withUnsafeMutableBytes {
            $0.initialize(to: 0, count: decodedDataLength)
        }
    }
}


