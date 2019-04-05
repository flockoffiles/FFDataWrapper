//
//  FFDataWrapper+Hashable.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 12/02/2018.
//  Copyright © 2018 Flock of Files. All rights reserved.
//

import Foundation

extension FFDataWrapper: Hashable {
    /// NOTE: The implementation does NOT take extra info into account (in case InfoCoder is being used).
    public func hash(into hasher: inout Hasher) {
        mapData({ (data: inout Data) -> Void in
            hasher.combine(data)
        })
    }
    
    /// NOTE: The implementation does NOT take extra info into account (in case InfoCoder is being used).
    public static func ==(lhs: FFDataWrapper, rhs: FFDataWrapper) -> Bool {
        return lhs.mapData({ (lhsData: inout Data) -> Bool in
            return rhs.mapData({ (rhsData: inout Data) -> Bool in
                return lhsData == rhsData
            })
        })
    }
}

