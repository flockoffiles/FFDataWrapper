//
//  FFDataWrapper+Conversions.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 09/02/2018.
//  Copyright © 2018 Flock of Files. All rights reserved.
//

import Foundation

#if DEBUG
extension FFDataWrapper: CustomStringConvertible
{
    public static func hexString(_ data: Data) -> String
    {
        var result = String()
        result.reserveCapacity(data.count * 2)
        for i in 0 ..< data.count
        {
            result += String(format: "%02X", data[i])
        }
        return result
    }
    
    func underlyingDataString() -> String
    {
        return self.withDecodedData { decodedData -> String in
            if let dataAsString = String(data: decodedData, encoding: .utf8)
            {
                return dataAsString
            }
            return FFDataWrapper.hexString(decodedData)
        }
    }
    
    public var description: String {
        return "FFDataWrapper: \(underlyingDataString())"
    }
}

extension FFDataWrapper: CustomDebugStringConvertible
{
    public var debugDescription: String {
        var result = "FFDataWrapper:\n"
        result += "Underlying data: \"\(underlyingDataString())\"\n"
        result += "dataRef: \(String(reflecting:dataRef))\n"
        result += "encoder: \(String(reflecting:self.coders.encoder))\n"
        result += "decoder: \(String(reflecting:self.coders.decoder))"
        return result
    }
}

extension FFDataWrapper: CustomPlaygroundDisplayConvertible
{
    public var playgroundDescription: Any
    {
        return self.description
    }
}
#endif

