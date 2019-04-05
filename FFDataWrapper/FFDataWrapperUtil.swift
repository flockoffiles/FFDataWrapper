//
//  FFDataWrapperUtil.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 29/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

public extension FFDataWrapper {
    /// Wipe the contents of data by zeroing out internal storage.
    /// This ONLY works if there are no more references to the data storage of the pertaining data.
    /// - Parameter data: The data to wipe
    static func wipe(_ data: inout Data) {
        data.resetBytes(in: 0 ..< data.count)
    }

    /// Try to wipe to contents of the underlying storage by replacing the characters with '\0'
    /// This is NOT guaranteed to work, and might work only if there are no more references to the string's backing storage.
    /// - Parameter string: The string to wipe.
    static func wipe(_ string: inout String) {
        let empty = String(repeating: "\0", count: string.count)
        string.replaceSubrange(string.startIndex ..< string.endIndex, with: empty)
    }

}


