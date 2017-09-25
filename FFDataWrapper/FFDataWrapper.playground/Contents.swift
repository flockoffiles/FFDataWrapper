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




//var wrapper2: FFDataWrapper? = nil
//
//do {
//    var wrapper1 = FFDataWrapper(string: testString)
//    // wrapper2 = wrapper1
//    wrapper1.buffer.withUnsafeMutablePointerToElements {
//        bytesPtr = $0
//    }
//
//    print("Buffer contents: \(wrapper1.hexString())")
//    var last = isKnownUniquelyReferenced(&wrapper1.buffer)
//    let selfPtr = Unmanaged.passUnretained(wrapper1.buffer).toOpaque().assumingMemoryBound(to: FFManagedByteBuffer.self)
//    last = isKnownUniquelyReferenced(&selfPtr.pointee)
//    //last = isKnownUniquelyReferenced(&wrapper1.buffer)
//
//
//
//}
//
//let data = Data(bytes: bytesPtr!, count: testString.lengthOfBytes(using: .utf8))
//print(data.hexString())

