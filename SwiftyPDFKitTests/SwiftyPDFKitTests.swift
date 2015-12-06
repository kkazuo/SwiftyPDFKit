//
//  SwiftyPDFKitTests.swift
//  SwiftyPDFKitTests
//
//  Created by Kazuo Koga on 2015/12/04.
/*
Copyright (c) 2015 Kazuo Koga

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import XCTest
@testable import SwiftyPDFKit

class SwiftyPDFKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCreate() {
        let source = NSURL(fileURLWithPath: "/tmp/asiabsdcon08-network.pdf")
        guard let doc = CGPDFDocumentCreateWithURL(source) else {
            XCTAssert(false)
            return
        }
        XCTAssertEqual(doc.numberOfPages, 6)
        XCTAssertEqual(doc.version, PDFVersion(major: 1, minor: 3))
        XCTAssertEqual(doc.identifier.0.description, "<2592a7e9 5c829b0c b631af5b cbea464a>")
        XCTAssertEqual(doc.identifier.1.description, "<7be1906b 2ff65000 bc5f166e 87791f4a>")
        XCTAssertEqual((doc.info["Title"] as! String), "asiabsdcon.fm5")
        XCTAssertEqual(doc.title, "asiabsdcon.fm5")
        XCTAssertEqual(doc.subject, nil)
        XCTAssertEqual(doc.creator, "FrameMaker 6.0")

        let ols = doc.outlines
        XCTAssertEqual(ols.count, 10)
        XCTAssertEqual(ols[0].title, "Introduction")
        XCTAssertEqual(ols[0].page, 2)
        let page = CGPDFDocumentGetPage(doc, ols[0].page)
        XCTAssert(page != nil)
    }
}
