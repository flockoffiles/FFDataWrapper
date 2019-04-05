//
//  FFDataWrapper+Mapping.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 19/02/2019.
//  Copyright © 2019 Flock of Files. All rights reserved.
//

import Foundation

extension FFDataWrapper {
    /// Execute the given closure with wrapped data.
    /// If you used InfoCoder when you created the wrapper, you should use the second version of mapData to pass extra info.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    /// Wiping of the data will succeed ONLY if the data is not passed outside the closure (i.e. if there are no additional references to it
    /// by the time the closure completes).
    /// - Parameter block: The closure to execute.
    @discardableResult
    public func mapData<ResultType>(_ block: (inout Data) throws -> ResultType) rethrows -> ResultType {
        var decodedData = Data(repeating:0, count: dataRef.dataBuffer.count)
        
        let count = decodedData.withUnsafeMutableBytes({ (destPtr: UnsafeMutablePointer<UInt8>) -> Int in
            switch self.storedCoders {
            case .coders(_, let decoder):
                decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                        UnsafeMutableBufferPointer(start: destPtr, count: dataRef.dataBuffer.count))
                return dataRef.dataBuffer.count
            case .infoCoders(_, let decoder):
                decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                        UnsafeMutableBufferPointer(start: destPtr, count: dataRef.dataBuffer.count), nil)
                return dataRef.dataBuffer.count
            }
            
        })
        // Must NOT grow the buffer of decodedData (only shrink)
        if count < decodedData.count {
            decodedData.count = count
        }
        let result = try block(&decodedData)
        
        decodedData.resetBytes(in: 0 ..< decodedData.count)
        
        return result
    }
    
    /// Execute the given closure with wrapped data.
    /// This version takes some extra info and passes it to the decoder in case InfoCoder was used.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    /// Wiping of the data will succeed ONLY if the data is not passed outside the closure (i.e. if there are no additional references to it
    /// by the time the closure completes).
    /// - Parameter info: Extra info to pass to the decoder in case InfoCoder is being used.
    /// - Parameter block: The closure to execute.
    @discardableResult
    public func mapData<ResultType>(info: Any?, block: (inout Data) throws -> ResultType) rethrows -> ResultType {
        var decodedData = Data(repeating:0, count: dataRef.dataBuffer.count)
        
        decodedData.withUnsafeMutableBytes({ (destPtr: UnsafeMutablePointer<UInt8>) -> Void in
            switch self.storedCoders {
            case .coders(_, let decoder):
                decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                        UnsafeMutableBufferPointer(start: destPtr, count: dataRef.dataBuffer.count))
            case .infoCoders(_, let decoder):
                decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                        UnsafeMutableBufferPointer(start: destPtr, count: dataRef.dataBuffer.count), info)
            }
        })
        let result = try block(&decodedData)
        decodedData.resetBytes(in: 0 ..< decodedData.count)
        return result
    }
    
    /// Will be deprecated soon. Please use mapData instead.
    @available(*, deprecated, message: "This method is deprecated. Please use mapData instead")
    @discardableResult
    public func withDecodedData<ResultType>(_ block: (inout Data) throws -> ResultType) rethrows -> ResultType {
        return try mapData(block)
    }
    

}
