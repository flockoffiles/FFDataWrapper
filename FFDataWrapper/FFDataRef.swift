//
//  FFDataRef.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 26/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

/// Helper class which makes sure that the internal representation gets wiped securely when FFDataWrapper is destroyed.
internal class FFDataRef
{
    /// Pointer to the data buffer holding the internal representation of the wrapper data.
    let dataBuffer: UnsafeMutableBufferPointer<UInt8>
    
    /// Create a buffer holder with the given initialized buffer.
    ///
    /// - Parameters:
    ///   - length: Actual buffer length.
    init(length: Int)
    {
        self.dataBuffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>.allocate(capacity: length), count: length)
    }
    
    deinit
    {
        // Explicitly clear the buffer (important)!
        dataBuffer.baseAddress!.initialize(repeating: 0, count: dataBuffer.count)
        dataBuffer.baseAddress!.deallocate()
    }
}

extension FFDataRef: CustomStringConvertible
{
    static func hexString(_ dataBuffer: UnsafePointer<UInt8>, _ length: Int) -> String
    {
        var result = String()
        result.reserveCapacity(length * 2)
        for i in 0 ..< length
        {
            result += String(format: "%02X", dataBuffer[i])
        }
        return result
    }

    public var description: String {
        let content = type(of: self).hexString(dataBuffer.baseAddress!, dataBuffer.count)
        return "FFDataRef: \(content)"
    }
}

