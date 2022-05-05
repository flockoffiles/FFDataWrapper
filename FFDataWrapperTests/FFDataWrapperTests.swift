//
//  FFDataWrapperTests.swift
//  FFDataWrapperTests
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import XCTest
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

class FFDataWrapperTests: XCTestCase
{
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    let testString = "ABCDEFGH"

    func testWrapStringWithXOR()
    {
        let wrapper1 = FFDataWrapper(string: testString)
        
        var recoveredString = ""
        wrapper1.mapData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
        
        print(wrapper1.dataRef.dataBuffer)
        let testData = testString.data(using: .utf8)!
        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer.baseAddress!, count: wrapper1.dataRef.dataBuffer.count)
        XCTAssertNotEqual(underlyingData, testData)

        
        let wrapper2 = wrapper1
        wrapper2.mapData { data in
            recoveredString = String(data: data, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
        
    }
    
    func testWraperStringWithCopy()
    {
        let wrapper1 = FFDataWrapper(string: testString, coders: FFDataWrapperEncoders.identity.coders)
        
        var recoveredString = ""
        wrapper1.mapData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
        
        let testData = testString.data(using: .utf8)!
        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer.baseAddress!, count: wrapper1.dataRef.dataBuffer.count)
        XCTAssertEqual(underlyingData, testData)
        
        let wrapper2 = wrapper1
        wrapper2.mapData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
    }
    
    func testWraperDataWithXOR()
    {
        let testData = testString.data(using: .utf8)!
        
        let wrapper1 = FFDataWrapper(data: testData)
        
        var recoveredString = ""
        wrapper1.mapData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }

        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer.baseAddress!, count: wrapper1.dataRef.dataBuffer.count)
        XCTAssertNotEqual(underlyingData, testData)

        let wrapper2 = wrapper1
        wrapper2.mapData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
    }
    
    /// Here we test that the temporary data which is given to the closure gets really wiped.
    /// This is the case where the data is NOT copied out.
    func testWipeAfterDecode()
    {
        // Inline data: 14 bytes
        //
        let testString = "ABCDEF0123456789ABCDEF"
        let testData = testString.data(using: .utf8)!
        let testDataLength = testData.count
        
        let dataWrapper = FFDataWrapper(data: testData)
        var copiedBacking = Data()
        
        let bytes: UnsafePointer<UInt8> = dataWrapper.mapData({ (data: inout Data) -> UnsafePointer<UInt8> in
            return data.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) -> UnsafePointer<UInt8> in
                copiedBacking = Data(bytes: ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), count: data.count)
                return ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
            })
        })
        
        let copiedBackingString = String(data: copiedBacking, encoding: .utf8)
        XCTAssertEqual(copiedBackingString, testString)
        let reconstructedBacking = Data(bytes: bytes, count: testDataLength)
        
        XCTAssertNotEqual(reconstructedBacking, copiedBacking)
    }
    
    #if swift(>=5.5.2) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testAsync() async {
        // Inline data: 14 bytes
        //
        let testString = "ABCDEF0123456789ABCDEF"
        let testData = testString.data(using: .utf8)!
        let testDataLength = testData.count
        
        let dataWrapper = FFDataWrapper(data: testData)
        var copiedBacking = Data()

        let bytes: UnsafePointer<UInt8> = await dataWrapper.mapData { (data: inout Data) async -> UnsafePointer<UInt8> in
            await withUnsafeContinuation { continuation in
                let pointer = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> UnsafePointer<UInt8> in
                    copiedBacking = Data(bytes: ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), count: data.count)
                    return ptr.baseAddress!.assumingMemoryBound(to: UInt8.self)
                }
                continuation.resume(returning: pointer)
            }
        }
        
        let copiedBackingString = String(data: copiedBacking, encoding: .utf8)
        XCTAssertEqual(copiedBackingString, testString)
        let reconstructedBacking = Data(bytes: bytes, count: testDataLength)
        
        XCTAssertNotEqual(reconstructedBacking, copiedBacking)
    }
    #endif
    
    struct StructWithSensitiveData: Decodable
    {
        var name: String
        var sensitive: FFDataWrapper
    }
    
    func testJSONDecoding()
    {
        let testJSONString = """
{
   \"name\": \"Test name\",
   \"sensitive\": \"Test sensitive\"
}
"""
        let jsonData = testJSONString.data(using: .utf8)!
        
        let decoder = TestJSONDecoder()
        decoder.userInfo = [FFDataWrapper.originalDataTypeInfoKey: String.self]
        
        let decoded = try! decoder.decode(StructWithSensitiveData.self, from: jsonData)
        
        print(decoded)
        decoded.sensitive.mapData {
            print(String(data: $0, encoding: .utf8)!)
        }
        
    }
    
}
