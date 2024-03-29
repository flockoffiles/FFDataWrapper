//
//  FFDataWrapper+Data.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 18/02/2019.
//  Copyright © 2019 Flock of Files. All rights reserved.
//

import Foundation

public extension FFDataWrapper {
    /// Create a wrapper with the given data content and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameters:
    ///   - data: The data to wrap.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    init(data: Data,
                coders: (encoder: FFDataWrapper.Coder, decoder: FFDataWrapper.Coder)? = nil,
                encode: Bool = true) {
        let unwrappedCoders = coders.unwrapWithDefault(length: data.count)
        self.storedCoders = CodersEnum(coders: unwrappedCoders)
        dataRef = FFDataRef(length: data.count)
        
        if (data.count > 0) {
            // Encode the data
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Void in
                let startPtr = UnsafeBufferPointer(start: bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), count: data.count)
                let endPtr = UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count)
                if encode {
                    unwrappedCoders.encoder(startPtr, endPtr)
                } else {
                    FFDataWrapperEncoders.identity.coders.encoder(startPtr, endPtr)
                }
            }
        }
    }

    @available(*, deprecated, message: "This method is deprecated. Please use init(data:coders:encode) instead")
    init(_ data: Data,
                _ coders: (encoder: FFDataWrapper.Coder, decoder: FFDataWrapper.Coder)? = nil,
                _ encode: Bool = true) {
        self.init(data: data, coders: coders, encode: encode)
    }

    /// Create a wrapper with the given data content and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameters:
    ///   - data: The data to wrap.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - info: Additional info to pass to the coders.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    init(data: Data,
                infoCoders: FFDataWrapper.InfoCoders? = nil,
                info: Any? = nil,
                encode: Bool = true) {
        let unwrappedCoders = infoCoders.unwrapWithDefault(length: data.count)
        self.storedCoders = CodersEnum(infoCoders: unwrappedCoders)
        dataRef = FFDataRef(length: data.count)
        
        if (data.count > 0) {
            // Encode the data
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.infoIdentityFunction()
                initialEncoder(UnsafeBufferPointer(start: bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), count: data.count),
                               UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count),
                               info)
            }
        }
    }

}
