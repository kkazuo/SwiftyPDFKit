//
//  Document.swift
//  SwiftyPDFKit
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

import Foundation
import CoreGraphics

extension CGPDFDocumentRef {
    
    public var numberOfPages: Int {
        return CGPDFDocumentGetNumberOfPages(self)
    }
    
    public var catalog: PDFDictionaryType {
        return CGPDFDocumentGetCatalog(self).shallowCopy()
    }

    public var info: PDFDictionaryType {
        return CGPDFDocumentGetInfo(self).shallowCopy()
    }

    public var version: PDFVersion {
        var version = PDFVersion(major: 0, minor: 0)
        withUnsafeMutablePointers(&version.major, &version.minor) {
            CGPDFDocumentGetVersion(self, $0, $1)
        }
        return version
    }
    
    public var identifier: (NSData, NSData) {
        let a = CGPDFDocumentGetID(self)
        if CGPDFArrayGetCount(a) == 2 {
            var s1 = CGPDFStringRef()
            var s2 = CGPDFStringRef()
            if (withUnsafeMutablePointers(&s1, &s2) { CGPDFArrayGetString(a, 0, $0) && CGPDFArrayGetString(a, 1, $1) }) {
                return (NSData(bytes: CGPDFStringGetBytePtr(s1), length: CGPDFStringGetLength(s1)),
                    NSData(bytes: CGPDFStringGetBytePtr(s2), length: CGPDFStringGetLength(s2)))
            }
        }
        return (NSData(), NSData())
    }
    
    public var outlines: [OutlineElement] {
        let catalog = CGPDFDocumentGetCatalog(self)
        if let ol = catalog[dictionary: "Outlines"] {
            return ol.outlines()
                // decoupling from self.
                .map { $0 }
        } else {
            return []
        }
    }
}
