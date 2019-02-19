//
//  FFDataWrapper.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation


/// FFDataWrapper is a struct which wraps a piece of data and provides some custom internal representation for it.
/// Conversions between original and internal representations can be specified with encoder and decoder closures.
public struct FFDataWrapper {
    /// This coder transforms data in its first argument and writes the result into its second argument.
    public typealias Coder = (UnsafeBufferPointer<UInt8>, UnsafeMutableBufferPointer<UInt8>) -> Void
    public typealias Coders = (encoder: Coder, decoder: Coder)
    /// This coder transforms data in its first argument and writes the result into its second argument.
    /// It optionally takes some extra info that it can use to perform the transformation
    public typealias InfoCoder = (UnsafeBufferPointer<UInt8>, UnsafeMutableBufferPointer<UInt8>, Any?) -> Void
    public typealias InfoCoders = (encoder: InfoCoder, decoder: InfoCoder)
    
    internal enum CodersEnum {
        case coders(encoder: Coder, decoder: Coder)
        case infoCoders(encoder: InfoCoder, decoder: InfoCoder)
    }
    
    /// Class holding the data buffer and responsible for wiping the data when FFDataWrapper is destroyed.
    internal let dataRef: FFDataRef
    
    /// Closures to convert external representation to internal and back
    internal let storedCoders: CodersEnum
    
    /// Returns true if the wrapped data is empty; false otherwise.
    public var isEmpty: Bool {
        return dataRef.dataBuffer.count == 0
    }
    
    /// Returns the length of the underlying data
    public var length: Int {
        return dataRef.dataBuffer.count
    }
    
    /// Returns the raw internal storage data.
    public var rawData: Data {
        return Data(dataRef.dataBuffer)
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
    return try w1.mapData({ (w1Data: inout Data) -> ResultType in
        return try w2.mapData({ (w2Data: inout Data) -> ResultType in
            return try block(&w1Data, &w2Data)
        })
    })
}





