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
    
    public var rawData: Data
    {
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
    return try w1.withDecodedData({ (w1Data: inout Data) -> ResultType in
        return try w2.withDecodedData({ (w2Data: inout Data) -> ResultType in
            return try block(&w1Data, &w2Data)
        })
    })
}





