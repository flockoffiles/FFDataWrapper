//
//  FFDataWrapper+Initialization.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 09/02/2018.
//  Copyright © 2018 Flock of Files. All rights reserved.
//

import Foundation

extension FFDataWrapper.CodersEnum {
    init(coders: FFDataWrapper.Coders?) {
        if let coders = coders {
            self = .coders(encoder: coders.encoder, decoder: coders.decoder)
        } else {
            let coders = FFDataWrapperEncoders.xorWithRandomVectorOfLength(0).coders
            self = .coders(encoder: coders.encoder, decoder: coders.decoder)
        }
    }
}

extension Optional where Wrapped == FFDataWrapper.Coders {
    func unwrapWithDefault(length: Int) -> FFDataWrapper.Coders  {
        switch self {
        case .some(let encoder, let decoder):
            return (encoder, decoder)
        case .none:
            return FFDataWrapperEncoders.xorWithRandomVectorOfLength(length).coders
        }
    }
}

extension FFDataWrapper {
    /// Create a wrapper for an empty value and use the default transformation for internal representation (not really applied, just for consistency reasons).
    public init() {
        self.init(coders: nil)
    }

    /// Create a wrapper for an empty data value and use the specified pair of coders to convert to/from the internal representation.
    ///
    /// - Parameter coders: Pair of coders to use to convert to/from the internal representation. If nil, the default XOR coders will be used.
    public init(coders: Coders? = nil) {
        self.storedCoders = CodersEnum(coders: coders.unwrapWithDefault(length: 0))
        dataRef = FFDataRef(length: 0)
    }

    @available(*, deprecated, message: "This method is deprecated. Please use init(coders:) instead")
    public init(_ coders: Coders? = nil) {
        self.init(coders: coders)
    }

    /// Create a wrapper of the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - coders: Pair of coders to use to convert to/from the internal representation. If nil, the default coders will be used.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                coders: FFDataWrapper.Coders? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        
        guard length > 0 else {
            self.storedCoders = CodersEnum(coders: coders.unwrapWithDefault(length: 0))
            self.dataRef = FFDataRef(length: 0)
            return
        }
        let unwrappedCoders = coders.unwrapWithDefault(length: length)
        self.storedCoders = CodersEnum(coders: unwrappedCoders)
        self.dataRef = FFDataRef(length: length)
        
        let tempBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer {
            tempBufferPtr.initialize(repeating: 0, count: length)
            tempBufferPtr.deallocate()
        }
        
        try initializer(UnsafeMutableBufferPointer(start: tempBufferPtr, count: length))
        let initialEncoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.identity.coders.encoder
        initialEncoder(UnsafeBufferPointer(start: tempBufferPtr, count: length),
                       UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: length))
    }

    /// Create a wrapper of the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - coder: Coder to convert to and from the internal representation.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                coder: @escaping FFDataWrapper.Coder,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) throws {
        let coders: FFDataWrapper.Coders? = FFDataWrapper.Coders(coder, coder)
        try self.init(length: length, coders: coders, encode: encode, initializer: initializer)
    }

    /// Create a wrapper of the given length and the given initializer closure.
    /// The initializer closure is used to set the initial data contents.
    /// - Parameters:
    ///   - length: The desired length.
    ///   - coder: Coder to convert to and from the internal representation.
    ///   - encode: If true (default), the initial data constructed with the initializer closure will be encoded; if false, it won't be encoded
    ///             and will be assumed to be already encoded.
    ///   - initializer: Initializer closure to set initial contents.
    public init(length: Int,
                coder: @escaping FFDataWrapper.Coder,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>) -> Void) {
        let coders: FFDataWrapper.Coders? = FFDataWrapper.Coders(coder, coder)
        try! self.init(length: length, coders: coders, encode: encode, initializer: initializer)
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
                coders: FFDataWrapper.Coders? = nil,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) throws -> Void) rethrows {
        
        guard capacity > 0 else {
            self.storedCoders = CodersEnum(coders: coders.unwrapWithDefault(length: 0))
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
            self.storedCoders = CodersEnum(coders: coders.unwrapWithDefault(length: 0))
            self.dataRef = FFDataRef(length: 0)
            return
        }
        
        let unwrappedCoders = coders.unwrapWithDefault(length: actualLength)
        self.storedCoders = CodersEnum(coders: unwrappedCoders)
        
        self.dataRef = FFDataRef(length: actualLength)
        let encoder = encode ? unwrappedCoders.encoder : FFDataWrapperEncoders.identity.coders.encoder
        encoder(UnsafeBufferPointer(start: tempBufferPtr, count: actualLength),
                UnsafeMutableBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: self.dataRef.dataBuffer.count))
        
    }

    public init(capacity: Int,
                coder: @escaping FFDataWrapper.Coder,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) throws -> Void) throws {
        let coders = FFDataWrapper.Coders(coder, coder)
        try self.init(capacity: capacity, coders: coders, encode: encode, initializer: initializer)
    }

    public init(capacity: Int,
                coder: @escaping FFDataWrapper.Coder,
                encode: Bool = true,
                initializer: (UnsafeMutableBufferPointer<UInt8>, UnsafeMutablePointer<Int>) -> Void) {
        let coders = FFDataWrapper.Coders(coder, coder)
        try! self.init(capacity: capacity, coders: coders, encode: encode, initializer: initializer)
    }

}

