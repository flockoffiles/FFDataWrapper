//
//  FFDataWrapper+ByteArray.swift
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
    ///   - byteArray: The data to wrap.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    public init(byteArray: [UInt8],
                coders: FFDataWrapper.Coders? = nil,
                encode: Bool = true) {
        let unwrappedCoders = coders.unwrapWithDefault(length: byteArray.count)
        self.storedCoders = CodersEnum(coders: unwrappedCoders)

        dataRef = FFDataRef(length: byteArray.count)
        
        if (byteArray.count > 0) {
            let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.identity.coders.encoder
            // Encode the data
            byteArray.withUnsafeBufferPointer {
                initialEncoder($0, UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count))
            }
        }
    }

    @available(*, deprecated: 1.6, message: "This method is deprecated. Please use init(byteArray:coders:encode) instead")
    public init(_ byteArray: [UInt8],
                _ coders: (encoder: FFDataWrapper.Coder, decoder: FFDataWrapper.Coder)? = nil,
                _ encode: Bool = true) {
        self.init(byteArray: byteArray, coders: coders, encode: encode)
    }
    
    /// Create a wrapper with the given data content and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameters:
    ///   - byteArray: The data to wrap.
    ///   - infoCoders: Pair of coders to use to convert to/from the internal representation. If nil, the default coders will be used.
    ///   - info: Additional info to pass to the coders.
    ///   - encode: If true, encoder will be applied to the provided string; if false, the string will be assumed to already contain
    ///          already encoded underlying representation.
    public init(byteArray: [UInt8],
                infoCoders: FFDataWrapper.InfoCoders? = nil,
                info: Any? = nil,
                encode: Bool = true) {
        let unwrappedCoders = infoCoders.unwrapWithDefault(length: byteArray.count)
        self.storedCoders = CodersEnum(infoCoders: unwrappedCoders)
        dataRef = FFDataRef(length: byteArray.count)
        
        if (byteArray.count > 0) {
            let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.infoIdentityFunction()
            // Encode the data
            byteArray.withUnsafeBufferPointer {
                initialEncoder($0, UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count), info)
            }
        }
    }

}
