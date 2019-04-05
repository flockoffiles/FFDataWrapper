//
//  FFDataWrapper+String.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 18/02/2019.
//  Copyright © 2019 Flock of Files. All rights reserved.
//

import Foundation

public extension FFDataWrapper {
    /// Initialize the data wrapper with the given string content and a pair of coder/decoder to convert between representations.
    ///
    /// - Parameters:
    ///   - string: The string data to wrap. The string gets converted to UTF8 data before being fed to the encoder closure.
    ///   - coders: The encoder/decoder pair which performs the conversion between external and internal representations. If nil, the default XOR coders will be used.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    init(string: String,
                coders: (encoder: FFDataWrapper.Coder, decoder: FFDataWrapper.Coder)? = nil,
                encode: Bool = true) {
        
        let utf8 = string.utf8CString
        let length = string.lengthOfBytes(using: .utf8) // utf8.count also accounts for the last 0 byte.
        let unwrappedCoders = coders.unwrapWithDefault(length: length)
        self.storedCoders = CodersEnum(coders: unwrappedCoders)
        self.dataRef = FFDataRef(length: length)
        
        // If length is 0 there may not be a pointer to the string content
        if (length > 0) {
            // Obfuscate the data
            utf8.withUnsafeBytes {
                let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.identity.coders.encoder
                initialEncoder(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: UInt8.self), count: length),
                               UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: length))
            }
        }
    }

    @available(*, deprecated, message: "This method is deprecated. Please use init(string:coders:encode) instead")
    init(_ string: String,
                _ coders: (encoder: FFDataWrapper.Coder, decoder: FFDataWrapper.Coder)? = nil,
                _ encode: Bool = true) {
        self.init(string: string, coders: coders, encode: encode)
    }
    
    /// Initialize the data wrapper with the given string content and a pair of coder/decoder to convert between representations.
    ///
    /// - Parameters:
    ///   - string: The string data to wrap. The string gets converted to UTF8 data before being fed to the encoder closure.
    ///   - infoCoders: The encoder/decoder pair which performs the conversion between external and internal representations. If nil, the default coders will be used.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    init(_ string: String,
                infoCoders: FFDataWrapper.InfoCoders? = nil,
                info: Any? = nil,
                encode: Bool = true) {
        let utf8 = string.utf8CString
        let length = string.lengthOfBytes(using: .utf8) // utf8.count also accounts for the last 0 byte.
        dataRef = FFDataRef(length: length)
        let unwrappedCoders = infoCoders.unwrapWithDefault(length: length)
        self.storedCoders = CodersEnum(infoCoders: unwrappedCoders)

        if (length > 0) {
            // Encode the data
            utf8.withUnsafeBytes {
                let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.infoIdentityFunction()
                initialEncoder(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: UInt8.self), count: length),
                               UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: length), info)
            }
        }
    }

}
