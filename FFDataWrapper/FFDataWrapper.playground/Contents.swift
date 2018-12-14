//: Playground - noun: a place where people can play

import Foundation
@testable import FFDataWrapper

extension Data {
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

func address(_ o: UnsafeRawPointer) -> UnsafeRawPointer
{
    return o
}

let data = Data(bytes: [65, 1, 3])






















