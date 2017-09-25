//
//  FFDataWrapperTests.swift
//  FFDataWrapperTests
//
//  Created by Sergey Novitsky on 21/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import XCTest
@testable import FFDataWrapper

class FFDataWrapperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWrapStringWithXOR()
    {
        let testString = "ABCDEFG"
        
        let wrapper1 = FFDataWrapper(testString)
        
        wrapper1.withDecodedData {
            let recoveredString = String(data: $0, encoding: .utf8)
            XCTAssertEqual(recoveredString, testString)
        }
        
    }
    
    
}
