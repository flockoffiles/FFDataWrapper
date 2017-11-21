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
    let shortTestString = "A"
    let utf16TestString = "AB❤️💛❌✅"
    let wipeCharacter = UInt8(46)

    func testUnsafeWipeUtf8String()
    {
        let expectedWipedString = String(testString.map { _ in Character(UnicodeScalar(wipeCharacter)) })
        var testUtf8String = String()
        testUtf8String.append(testString)
        
        FFDataWrapper.unsafeWipe(&testUtf8String, with: wipeCharacter)
        
        XCTAssertEqual(testUtf8String, expectedWipedString)
    }
    
    func testUnsafeWipeShortUtf8String()
    {
        let expectedWipedString = String(shortTestString.map { _ in Character(UnicodeScalar(wipeCharacter)) })
        var testUtf8String = String()
        testUtf8String.append(shortTestString)
        
        FFDataWrapper.unsafeWipe(&testUtf8String, with: wipeCharacter)
        
        XCTAssertEqual(testUtf8String, expectedWipedString)
    }
    
    func testUnsafeWipeUtf16String()
    {
        var testUtf16String = String()
        testUtf16String.append(utf16TestString)
        
        FFDataWrapper.unsafeWipe(&testUtf16String, with: wipeCharacter)
        
        let elements = Array(testUtf16String.utf16)
        elements.forEach {
            XCTAssertEqual($0, UInt16(wipeCharacter) * 256 + UInt16(wipeCharacter))
        }
    }
    
    func testUnsafeWipeSwiftMutableData()
    {
        var data = Data()
        data.append(testString.data(using: .utf8)!)
        
        let expectedData = Data(count: data.count)
        
        FFDataWrapper.unsafeWipe(&data)
        
        XCTAssertEqual(data, expectedData)
    }
    
    
    func testWrapStringWithXOR()
    {
        let wrapper1 = FFDataWrapper(testString)
        
        var recoveredString = ""
        wrapper1.withDecodedData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
        
        print(wrapper1.dataRef.dataBuffer)
        let testData = testString.data(using: .utf8)!
        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer.baseAddress!, count: wrapper1.dataRef.dataBuffer.count)
        XCTAssertNotEqual(underlyingData, testData)

        
        let wrapper2 = wrapper1
        wrapper2.withDecodedData { data in
            recoveredString = String(data: data, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
        
    }
    
    func testWraperStringWithCopy()
    {
        let wrapper1 = FFDataWrapper(testString, FFDataWrapperEncoders.identity.coders)
        
        var recoveredString = ""
        wrapper1.withDecodedData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
        
        let testData = testString.data(using: .utf8)!
        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer.baseAddress!, count: wrapper1.dataRef.dataBuffer.count)
        XCTAssertEqual(underlyingData, testData)
        
        let wrapper2 = wrapper1
        wrapper2.withDecodedData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
    }
    
    func testWraperDataWithXOR()
    {
        let testData = testString.data(using: .utf8)!
        
        let wrapper1 = FFDataWrapper(testData)
        
        var recoveredString = ""
        wrapper1.withDecodedData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }

        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer.baseAddress!, count: wrapper1.dataRef.dataBuffer.count)
        XCTAssertNotEqual(underlyingData, testData)

        let wrapper2 = wrapper1
        wrapper2.withDecodedData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
    }
    
    /// Here we test that the temporary data which is given to the closure gets really wiped.
    /// This is the case where the data is NOT copied out.
    func testWipeAfterDecode()
    {
        let testString = "ABCDEF"
        let testData = testString.data(using: .utf8)!
        let testDataLength = testData.count
        
        let dataWrapper = FFDataWrapper(testData)
        var copiedBacking = Data()
        
        guard let bytes: UnsafeMutableRawPointer = dataWrapper.withDecodedData({ (data: inout Data) -> UnsafeMutableRawPointer? in
            let dataAddress = { (_ o: UnsafeRawPointer) -> UnsafeRawPointer in o }(&data)
            let backingPtr = dataAddress.assumingMemoryBound(to: UnsafeMutableRawPointer.self).pointee
            // We cannot instantiate FFDataStorage by pointee here because it will mess up the memory!
            if let bytes = backingPtr.advanced(by: MemoryLayout<FFClassHeader>.size).assumingMemoryBound(to: UnsafeMutableRawPointer?.self).pointee
            {
                copiedBacking = Data(bytes: bytes, count: data.count)
                return bytes
            }
            return nil
        }) else {
            XCTFail("Expecting to have a data storage")
            return
        }
        
        let copiedBackingString = String(data: copiedBacking, encoding: .utf8)
        XCTAssertEqual(copiedBackingString, testString)
        let reconstructedBacking = Data(bytes: bytes, count: testDataLength)
        
        let expectedReconstructedBacking = Data.init(count: testDataLength)
        XCTAssertEqual(reconstructedBacking, expectedReconstructedBacking)
    }
    
    func testUnsafeWipeNSMutableData()
    {
        let nsData = NSMutableData()
        var testData = testString.data(using: .utf8)!
        let length = testData.count
        testData.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            nsData.append(bytes, length: length)
        }
        
        // let nsDataBytes = nsData.bytes
        
        var data = nsData as Data
        var data2: Data?
        Data._forceBridgeFromObjectiveC(nsData, result: &data2)
        // var bridgedNSData = data as NSData
        // var bridgedNSData2 = data._bridgeToObjectiveC()
        FFDataWrapper.unsafeWipe(&data)
        
        let expectedData = Data(count: length)
        
        XCTAssertEqual(data, expectedData)
        let expectedNSData = NSMutableData()
        expectedData.withUnsafeBytes {
            expectedNSData.append($0, length: length)
        }
        
        
        // TODO: although we can wipe the native Swift data backing store,
        // we cannot get to the original NSString yet.
        // XCTAssertEqual(nsData, expectedNSData)
    }
    
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
        decoded.sensitive.withDecodedData {
            print(String(data: $0, encoding: .utf8)!)
        }
        
    }
    
}
