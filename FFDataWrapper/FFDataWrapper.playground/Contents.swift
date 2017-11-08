//: Playground - noun: a place where people can play

import Foundation
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

func address(_ o: UnsafeRawPointer) -> UnsafeRawPointer
{
    return o
}

let data = Data(bytes: [65, 1, 3])

struct FFStringCore
{
    var baseAddress: UnsafeMutableRawPointer?
    var countAndFlags: UInt
    var owner: AnyObject?
    
    /// Bitmask for the count part of `_countAndFlags`.
    var countMask: UInt {
        return UInt.max &>> 2
    }
    
    /// Bitmask for the flags part of `_countAndFlags`.
    var flagMask: UInt {
        return ~countMask
    }

    var count: Int {
        get {
            return Int(countAndFlags & countMask)
        }
    }
    
    /// Left shift amount to apply to an offset N so that when
    /// added to a UnsafeMutableRawPointer, it traverses N elements.
    var elementShift: Int {
        return Int(countAndFlags &>> (UInt.bitWidth - 1))
    }
    
    /// The number of bytes per element.
    ///
    /// If the string does not have an ASCII buffer available (including the case
    /// when we don't have a utf16 buffer) then it equals 2.
    public var elementWidth: Int {
        return elementShift &+ 1
    }
}

struct FFString
{
    var core: FFStringCore
}

var asciiString = "ABCDEFGH"
let asciiStringPtr = address(&asciiString)
let asciiStringCore = asciiStringPtr.assumingMemoryBound(to: FFString.self).pointee.core
let width = asciiStringCore.elementWidth
var length = asciiStringCore.count

var recoveredString: String = String(bytesNoCopy: asciiStringCore.baseAddress!, length: length, encoding: String.Encoding.utf8, freeWhenDone: false)!

let asciiBuffer = asciiStringCore.baseAddress!.assumingMemoryBound(to: UInt8.self)
asciiBuffer.initialize(to: 65, count: length*width)

recoveredString = String(bytesNoCopy: asciiStringCore.baseAddress!, length: length, encoding: String.Encoding.utf8, freeWhenDone: false)!

var shortAsciiString = "AB"
let shortAsciiStringPtr = address(&shortAsciiString)
let shortAsciiStringCore = shortAsciiStringPtr.assumingMemoryBound(to: FFString.self).pointee.core
let shortAsciiStringWidth = shortAsciiStringCore.elementWidth
let shortAsciiStringLength = shortAsciiStringCore.count

let shortAsciiStringBaseAddress = shortAsciiStringCore.baseAddress
recoveredString = String(bytesNoCopy: shortAsciiStringBaseAddress!, length: shortAsciiStringWidth * shortAsciiStringLength, encoding: String.Encoding.utf8, freeWhenDone: false)!

var unicodeString = "AB🍏🍊⚒✅"
let unicodeStringPtr = address(&unicodeString)
let unicodeStringCore = unicodeStringPtr.assumingMemoryBound(to: FFString.self).pointee.core
let unicodeStringWidth = unicodeStringCore.elementWidth
let unicodeStringLength = unicodeStringCore.count

let unicodeStringBuffer = unicodeStringCore.baseAddress!.assumingMemoryBound(to: UInt8.self)
let unicodeStringBaseAddress = unicodeStringCore.baseAddress!

let unicodeBuffer = unicodeStringBaseAddress.assumingMemoryBound(to: UInt16.self)

var recoveredUnicodeString = String(bytesNoCopy: unicodeBuffer, length:unicodeStringLength * unicodeStringWidth, encoding:String.Encoding.utf16LittleEndian, freeWhenDone: false)!

unicodeBuffer.initialize(to: 65, count: unicodeStringLength*unicodeStringWidth)
recoveredUnicodeString = String(bytesNoCopy: unicodeBuffer, length:unicodeStringLength * unicodeStringWidth, encoding:String.Encoding.utf16LittleEndian, freeWhenDone: false)!

let nsString = NSString(format: "ABCDEF")
let cocoaString: String = nsString as String

var nsData = NSMutableData()
var testData = "ABCDEF".data(using: .utf8)!
length = testData.count
testData.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
    nsData.append(bytes, length: length)
}

let testWrapper = FFDataWrapper("Test underlying string")
print(String(reflecting:testWrapper))























