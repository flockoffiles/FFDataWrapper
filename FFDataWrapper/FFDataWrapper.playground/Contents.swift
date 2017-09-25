//: Playground - noun: a place where people can play

import UIKit
@testable import FFDataWrapper

var bytesPtr: UnsafeMutablePointer<UInt8>? = nil
let testString = "ABCDEFG"

var w1DataPtr: UnsafePointer<UInt8>? = nil
var w1Length = 0

do {
    let w1 = FFDataWrapper(testString)
    w1Length = w1.data.count
    w1.data.withUnsafeBytes {
        w1DataPtr = $0
    }
    
    // let w2 = w1
}

