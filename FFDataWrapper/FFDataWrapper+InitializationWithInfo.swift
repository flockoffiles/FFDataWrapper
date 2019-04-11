//
//  FFDataWrapper+InitializationWithInfo.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 19/02/2019.
//  Copyright © 2019 Flock of Files. All rights reserved.
//

import Foundation

extension FFDataWrapper.CodersEnum {
    init(infoCoders: FFDataWrapper.InfoCoders?) {
        if let infoCoders = infoCoders {
            self = .infoCoders(encoder: infoCoders.encoder, decoder: infoCoders.decoder)
        } else {
            let coders = FFDataWrapperEncoders.xorWithRandomVectorOfLength(0).infoCoders
            self = .infoCoders(encoder: coders.encoder, decoder: coders.decoder)
        }
    }
}

extension Optional where Wrapped == FFDataWrapper.InfoCoders {
    func unwrapWithDefault(length: Int) -> FFDataWrapper.InfoCoders  {
        switch self {
        case .some(let encoder, let decoder):
            return (encoder, decoder)
        case .none:
            return FFDataWrapperEncoders.xorWithRandomVectorOfLength(length).infoCoders
        }
    }
}

extension FFDataWrapper {
    
    /// Create a wrapper of the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - infoCoders: Pair of coders to use to convert to/from the internal representation. If nil, the default coders will be used.
    ///   - info: Additional info to pass to the coders.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                infoCoders: FFDataWrapper.InfoCoders? = nil,
                info: Any? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        
        guard length > 0 else {
            self.storedCoders = CodersEnum(infoCoders: infoCoders.unwrapWithDefault(length: 0))
            self.dataRef = FFDataRef(length: 0)
            return
        }
        let unwrappedCoders = infoCoders.unwrapWithDefault(length: length)
        self.storedCoders = CodersEnum(infoCoders: unwrappedCoders)
        self.dataRef = FFDataRef(length: length)
        
        let tempBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer {
            tempBufferPtr.initialize(repeating: 0, count: length)
            tempBufferPtr.deallocate()
        }
        
        try initializer(UnsafeMutableBufferPointer(start: tempBufferPtr, count: length))
        let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.identity.infoCoders.encoder
        initialEncoder(UnsafeBufferPointer(start: tempBufferPtr, count: length),
                       UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: length), info)
    }

    /// Create a wrapper of the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - coder: Coder to convert to and from the internal representation.
    ///   - info: Additional info to pass to the coders.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                infoCoder: @escaping FFDataWrapper.InfoCoder,
                info: Any? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) throws {
        let coders: FFDataWrapper.InfoCoders? = FFDataWrapper.InfoCoders(infoCoder, infoCoder)
        try self.init(length: length, infoCoders: coders, info: info, encode: encode, initializer: initializer)
    }
    
    /// Create a wrapper of the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - coder: Coder to convert to and from the internal representation.
    ///   - info: Additional info to pass to the coders.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                infoCoder: @escaping FFDataWrapper.InfoCoder,
                info: Any? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>) -> Void) {
        let coders: FFDataWrapper.InfoCoders? = FFDataWrapper.InfoCoders(infoCoder, infoCoder)
        try! self.init(length: length, infoCoders: coders, info: info, encode: encode, initializer: initializer)
    }

    /// Create a wrapper with the given maximum capacity (in bytes).
    ///
    /// - Parameters:
    ///   - capacity: The desired capacity (in bytes)
    ///   - infoCoders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    ///   - info: Additional info to pass to the coders.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to create initial data contents. The size of created data can be smaller (but never greater)
    ///                  than the capacity. The initializer closure must return the actual length of the data in its second parameter.
    /// - Throws: Error if capacity is >= 0 or if the actual length turns out to exceed the capacity.
    public init(capacity: Int,
                infoCoders: FFDataWrapper.InfoCoders? = nil,
                info: Any? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) throws -> Void) rethrows {
        
        guard capacity > 0 else {
            self.storedCoders = CodersEnum(infoCoders: infoCoders.unwrapWithDefault(length: 0))
            self.dataRef = FFDataRef(length: 0)
            return
        }
        
        let tempBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        
        defer {
            // Securely wipe the temp buffer.
            tempBufferPtr.initialize(repeating: 0, count: capacity)
            tempBufferPtr.deallocate()
        }
        
        var actualLength = capacity
        try initializer(UnsafeMutableBufferPointer(start: tempBufferPtr, count: capacity), &actualLength)
        
        guard actualLength > 0 && actualLength <= capacity else {
            self.storedCoders = CodersEnum(infoCoders: infoCoders.unwrapWithDefault(length: 0))
            self.dataRef = FFDataRef(length: 0)
            return
        }
        
        let unwrappedCoders = infoCoders.unwrapWithDefault(length: actualLength)
        self.storedCoders = CodersEnum(infoCoders: unwrappedCoders)
        
        self.dataRef = FFDataRef(length: actualLength)
        let encoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.identity.infoCoders.encoder
        encoder(UnsafeBufferPointer(start: tempBufferPtr, count: actualLength),
                UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count), info)
        
    }

    public init(capacity: Int,
                infoCoder: @escaping FFDataWrapper.InfoCoder,
                info: Any? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) throws -> Void) throws {
        let coders = FFDataWrapper.InfoCoders(infoCoder, infoCoder)
        try self.init(capacity: capacity, infoCoders: coders, encode: encode, initializer: initializer)
    }
    
    public init(capacity: Int,
                infoCoder: @escaping FFDataWrapper.InfoCoder,
                info: Any? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) -> Void) {
        let coders = FFDataWrapper.InfoCoders(infoCoder, infoCoder)
        try! self.init(capacity: capacity, infoCoders: coders, encode: encode, initializer: initializer)
    }
}
