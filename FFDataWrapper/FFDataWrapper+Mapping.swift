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
        var decodedData = Data(repeating: 0, count: dataRef.dataBuffer.count)
        getDecodedData(&decodedData)
        
        defer {
            decodedData.resetBytes(in: 0 ..< decodedData.count)
        }
        
        let result = try block(&decodedData)
                
        return result
    }
    
    #if swift(>=5.5.2) && canImport(_Concurrency)
    /// Execute the given async closure with wrapped data.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    /// Wiping of the data will succeed ONLY if the data is not passed outside the closure (i.e. if there are no additional references to it
    /// by the time the closure completes).
    /// - Parameter block: The closure to execute.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public func mapData<ResultType>(_ block: (inout Data) async throws -> ResultType) async rethrows -> ResultType {
        var decodedData = Data(repeating: 0, count: dataRef.dataBuffer.count)
        getDecodedData(&decodedData)
        
        defer {
            decodedData.resetBytes(in: 0 ..< decodedData.count)
        }

        let result = try await block(&decodedData)
        
        return result
    }
    #endif
    
    /// Execute the given closure with wrapped data.
    /// This version takes some extra info and passes it to the decoder in case InfoCoder was used.
    /// Data is converted back from its internal representation and is wiped after the closure is completed.
    /// Wiping of the data will succeed ONLY if the data is not passed outside the closure (i.e. if there are no additional references to it
    /// by the time the closure completes).
    /// - Parameter info: Extra info to pass to the decoder in case InfoCoder is being used.
    /// - Parameter block: The closure to execute.
    @discardableResult
    public func mapData<ResultType>(info: Any?, block: (inout Data) throws -> ResultType) rethrows -> ResultType {
        var decodedData = Data(repeating: 0, count: dataRef.dataBuffer.count)
        getDecodedData(&decodedData, info: info)
        
        defer {
            decodedData.resetBytes(in: 0 ..< decodedData.count)
        }
        
        let result = try block(&decodedData)
        return result
    }
    
    func getDecodedData(_ decodedData: inout Data, info: Any? = nil) {
        decodedData.reserveCapacity(dataRef.dataBuffer.count)
        
        let count = decodedData.withUnsafeMutableBytes { destMutableRawBufferPtr -> Int in
            switch self.storedCoders {
            case .coders(_, let decoder):
                decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                        UnsafeMutableBufferPointer(start: destMutableRawBufferPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                                                   count: dataRef.dataBuffer.count))
            case .infoCoders(_, let decoder):
                decoder(UnsafeBufferPointer(start: self.dataRef.dataBuffer.baseAddress!, count: dataRef.dataBuffer.count),
                        UnsafeMutableBufferPointer(start: destMutableRawBufferPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                                                   count: dataRef.dataBuffer.count), info)
            }
            return dataRef.dataBuffer.count
        }

        // Must NOT grow the buffer of decodedData (only shrink)
        if count < decodedData.count {
            decodedData.count = count
        }
    }
    
    /// Will be deprecated soon. Please use mapData instead.
    @available(*, deprecated, message: "This method is deprecated. Please use mapData instead")
    @discardableResult
    public func withDecodedData<ResultType>(_ block: (inout Data) throws -> ResultType) rethrows -> ResultType {
        return try mapData(block)
    }
    

}
