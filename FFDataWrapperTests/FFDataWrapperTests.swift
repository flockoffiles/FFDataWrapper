//
//  FFDataWrapperTests.swift
//  FFDataWrapperTests
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import XCTest
@testable import FFDataWrapper

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
    
    let testString = "ABCD"

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
        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer, count: wrapper1.dataRef.length)
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
        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer, count: wrapper1.dataRef.length)
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

        let underlyingData = Data(bytes: wrapper1.dataRef.dataBuffer, count: wrapper1.dataRef.length)
        XCTAssertNotEqual(underlyingData, testData)

        let wrapper2 = wrapper1
        wrapper2.withDecodedData {
            recoveredString = String(data: $0, encoding: .utf8)!
            XCTAssertEqual(recoveredString, testString)
        }
    }
    
    
}
