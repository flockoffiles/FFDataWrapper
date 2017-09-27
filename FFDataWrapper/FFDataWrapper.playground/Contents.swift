//: Playground - noun: a place where people can play

import UIKit
@testable import FFDataWrapper

extension Data
{
    /// Convert data to a hex string
    ///
    /// - Returns: hex string representation of the data.
    func hexString() -> String
    {
        var result = String()
        result.reserveCapacity(self.count * 2)
        [UInt8](self).forEach { (aByte) in
            result += String(format: "%02X", aByte)
        }
        return result
    }

}


let testString = "ABCDEFG"
let testData = testString.data(using: .utf8)!
testData.hexString()

let w1 = FFDataWrapper(testData)

var decoded = w1.withDecodedData { $0 }
decoded.hexString()



