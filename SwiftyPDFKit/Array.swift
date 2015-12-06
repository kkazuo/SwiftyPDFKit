//
//  Array.swift
//  SwiftyPDFKit
//
//  Created by Kazuo Koga on 2015/12/06.
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

extension CGPDFArrayRef {

    var count: Int {
        return CGPDFArrayGetCount(self)
    }

    subscript(integer ix: Int) -> Int? {
        var value = CGPDFInteger()
        if withUnsafeMutablePointer(&value, { CGPDFArrayGetInteger(self, ix, $0) }) {
            return value
        } else {
            return nil
        }
    }

    subscript(name ix: Int) -> String? {
        var value: UnsafePointer<Int8> = nil
        if withUnsafeMutablePointer(&value, { CGPDFArrayGetName(self, ix, $0) }) {
            return String.fromCString(value)
        } else {
            return nil
        }
    }

    subscript(string ix: Int) -> String? {
        var value = CGPDFStringRef()
        if withUnsafeMutablePointer(&value, { CGPDFArrayGetString(self, ix, $0) }) {
            if let cs = CGPDFStringCopyTextString(value) {
                return cs as String
            }
        }
        return nil
    }

    subscript(dictionary ix: Int) -> CGPDFDictionaryRef? {
        var value = CGPDFDictionaryRef()
        if withUnsafeMutablePointer(&value, { CGPDFArrayGetDictionary(self, ix, $0) }) {
            return value
        } else {
            return nil
        }
    }

    subscript(array ix: Int) -> CGPDFArrayRef? {
        var value = CGPDFArrayRef()
        if withUnsafeMutablePointer(&value, { CGPDFArrayGetArray(self, ix, $0) }) {
            return value
        } else {
            return nil
        }
    }

    subscript(ix: Int) -> CGPDFObjectRef? {
        var value = CGPDFObjectRef()
        if withUnsafeMutablePointer(&value, { CGPDFArrayGetObject(self, ix, $0) }) {
            return value
        } else {
            return nil
        }
    }
}
