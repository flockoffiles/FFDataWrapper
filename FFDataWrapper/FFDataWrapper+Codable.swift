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
extension FFDataWrapper: Codable
{
    /// Encode the underlying data using the given encoder.
    /// By default encoding is done as Data. It's possible to override this and use UTF-8 string by specifying String.self as the value
    /// for key FFDataWrapper.originalDataTypeInfoKey in the encoder's userInfo dictionary.
    /// - Parameter encoder: The relevant encoder.
    /// - Throws: Error if encoding fails.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        try withDecodedData {
            if (encoder.userInfo[FFDataWrapper.originalDataTypeInfoKey] as? String.Type) != nil
            {
                // TODO: There is no way to securely wipe the string contents.
                if let stringValue = String(data: $0, encoding: .utf8)
                {
                    try container.encode(stringValue)
                }
                else
                {
                    try container.encode("")
                }
                return
            }
            try container.encode($0)
        }
    }
    
    
    /// Instantiate a data wrapper by decoding the given value.
    /// By default we expect a Data value encoded in some standard way.
    /// It's possible to indicate that we expect a String value by specifying String.self under the key FFDataWrapper.originalDataTypeInfoKey
    /// in the decoder's userInfo dictionary.
    /// - Parameter decoder: The relevant decoder
    /// - Throws: Error in case decoding fails.
    public init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        if (decoder.userInfo[FFDataWrapper.originalDataTypeInfoKey] as? String.Type) != nil
        {
            var string = try container.decode(String.self)
            if let coders = decoder.userInfo[type(of: self).codersInfoKey] as? (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)
            {
                self.init(string, coders)
            }
            else
            {
                self.init(string)
            }
            // TODO: This may not actually work if there are more references to the string's backing store.
            FFDataWrapper.wipe(&string)
        }
        else
        {
            var data = try container.decode(Data.self)
            if let coders = decoder.userInfo[type(of: self).codersInfoKey] as? (encoder: FFDataWrapperCoder, decoder: FFDataWrapperCoder)
            {
                self.init(data, coders)
            }
            else
            {
                self.init(data)
            }
            FFDataWrapper.wipe(&data)
        }
    }
    
    public static let codersInfoKey = CodingUserInfoKey(rawValue: "FFDataWrapperCoders")!
    public static let originalDataTypeInfoKey = CodingUserInfoKey(rawValue: "FFDataWrapperOriginalDataType")!
    
}

