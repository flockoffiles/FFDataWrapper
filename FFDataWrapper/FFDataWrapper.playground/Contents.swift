//: Playground - noun: a place where people can play

import UIKit
@testable import FFDataWrapper

var bytesPtr: UnsafeMutablePointer<UInt8>? = nil
let testString = "ABCDEFG"

let bufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: 0)

print(bufferPtr)


