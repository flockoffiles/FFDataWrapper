//
//  FFDataWrapperUtil.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 29/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

public extension Data
{
    /// Wipe the contents of mutable data.
    mutating public func wipe()
    {
        resetBytes(in: 0 ..< count)
        removeAll()
    }
}

public extension String
{
    /// Try to wipe to contents of the underlying storage by replacing the characters with '\0'
    /// (That's the best that we can hope for given current Swift's implementation. It works at least for ASCII and UTF8 strings)
    mutating public func wipe()
    {
        let empty = String(repeating: "\0", count: count)
        withMutableCharacters {
            $0.replaceSubrange($0.startIndex ..< $0.endIndex, with: empty)
        }
        removeAll()
    }
}
