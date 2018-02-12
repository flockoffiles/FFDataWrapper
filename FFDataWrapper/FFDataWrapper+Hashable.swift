//
//  FFDataWrapper+Hashable.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 12/02/2018.
//  Copyright © 2018 Flock of Files. All rights reserved.
//

import Foundation

extension FFDataWrapper: Hashable
{
    public var hashValue: Int {
        return withDecodedData({ (data: inout Data) -> Int in
            return data.hashValue
        })
    }
    
    public static func ==(lhs: FFDataWrapper, rhs: FFDataWrapper) -> Bool {
        return lhs.withDecodedData({ (lhsData: inout Data) -> Bool in
            return rhs.withDecodedData({ (rhsData: inout Data) -> Bool in
                return lhsData == rhsData
            })
        })
    }
}

