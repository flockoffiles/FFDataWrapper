//
//  FFDataWrapper+Codable.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 11/10/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

/// Implementation of Codable for the data wrapper.
/// Note: current implementation does NOT provide secure wiping of data/string artifacts which resulting from encoding.
extension FFDataWrapper: Codable {
    /// Encode the underlying data using the given encoder.
    /// By default encoding is done as Data. It's possible to override this and use UTF-8 string by specifying String.self as the value
    /// for key FFDataWrapper.originalDataTypeInfoKey in the encoder's userInfo dictionary.
    /// - Parameter encoder: The relevant encoder.
    /// - Throws: Error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let info = encoder.userInfo[FFDataWrapper.infoInfoKey] {
            try self.mapData(info: info, block: { (data: inout Data) in
                if (encoder.userInfo[FFDataWrapper.originalDataTypeInfoKey] as? String.Type) != nil {
                    // TODO: There is no way to securely wipe the string contents.
                    if let stringValue = String(data: data, encoding: .utf8) {
                        try container.encode(stringValue)
                    } else {
                        try container.encode("")
                    }
                    return
                }
                try container.encode(data)
            })
        } else {
            try mapData {
                if (encoder.userInfo[FFDataWrapper.originalDataTypeInfoKey] as? String.Type) != nil {
                    // TODO: There is no way to securely wipe the string contents.
                    if let stringValue = String(data: $0, encoding: .utf8) {
                        try container.encode(stringValue)
                    } else {
                        try container.encode("")
                    }
                    return
                }
                try container.encode($0)
            }
        }
    }
    
    /// Instantiate a data wrapper by decoding the given value.
    /// By default we expect a Data value encoded in some standard way.
    /// It's possible to indicate that we expect a String value by specifying String.self under the key FFDataWrapper.originalDataTypeInfoKey
    /// in the decoder's userInfo dictionary.
    /// - Parameter decoder: The relevant decoder
    /// - Throws: Error in case decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        var data = try { () throws -> Data in
            if (decoder.userInfo[FFDataWrapper.originalDataTypeInfoKey] as? String.Type) != nil {
                var string = try container.decode(String.self)
                defer {
                    // TODO: This may not actually work if there are more references to the string's backing store.
                    FFDataWrapper.wipe(&string)
                }
                return string.data(using: .utf8)!
            } else {
                return try container.decode(Data.self)
            }
        }()
        
        defer {
            // TODO: This may not actually work if there are more references to the data backing store.
            FFDataWrapper.wipe(&data)
        }
        
        if let coders = decoder.userInfo[type(of: self).codersInfoKey] as? FFDataWrapper.Coders {
            self.init(data: data, coders: coders)
        } else if let infoCoders = decoder.userInfo[type(of: self).codersInfoKey] as? FFDataWrapper.InfoCoders {
            self.init(data: data, infoCoders: infoCoders, info: decoder.userInfo[type(of: self).infoInfoKey])
        } else {
            self.init(data: data)
        }
    }
    
    public static let codersInfoKey = CodingUserInfoKey(rawValue: "FFDataWrapperCoders")!
    public static let originalDataTypeInfoKey = CodingUserInfoKey(rawValue: "FFDataWrapperOriginalDataType")!
    public static let infoInfoKey = CodingUserInfoKey(rawValue: "FFDataWrapperInfo")!
    
}

