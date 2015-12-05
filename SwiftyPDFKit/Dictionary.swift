//
//  Dictionary.swift
//  SwiftyPDFKit
//
//  Created by Kazuo Koga on 2015/12/05.
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

extension CGPDFDictionaryRef {
    
    func shallowCopy() -> PDFDictionaryType {
        let f: CGPDFDictionaryApplierFunction = { ckey, obj, ctx in
            var dict = UnsafeMutablePointer<PDFDictionaryType>(ctx).memory
            guard let key = String.fromCString(ckey) else {
                return
            }
            switch CGPDFObjectGetType(obj) {
            case .Null:
                dict[key] = NSNull()
                
            case .Boolean:
                var bool = false
                bool = withUnsafeMutablePointer(&bool) { v in
                    CGPDFObjectGetValue(obj, .Boolean, v)
                    return v.memory
                }
                dict[key] = bool
                
            case .Integer: 0
                
            case .Real: 0
                
            case .Name:
                var cc: CChar = 0
                let s: String? = withUnsafeMutablePointer(&cc) { v in
                    CGPDFObjectGetValue(obj, .Name, v)
                    return String.fromCString(v)
                }
                if let s = s {
                    dict[key] = s
                }
                
            case .String:
                var ps = CGPDFStringRef()
                let s: AnyObject? = withUnsafeMutablePointer(&ps) { v in
                    CGPDFObjectGetValue(obj, .String, v)
                    if let cd = CGPDFStringCopyDate(v.memory) {
                        return cd as NSDate
                    }
                    if let cs = CGPDFStringCopyTextString(v.memory) {
                        return cs as String
                    }
                    return nil
                }
                if let s = s {
                    dict[key] = s
                }
                
            case .Array:
                dict[key] = []
                
            case .Dictionary:
                dict[key] = [:]
                
            case .Stream: 0
            }
            
            UnsafeMutablePointer<PDFDictionaryType>(ctx).memory = dict
        }
        
        var dict: PDFDictionaryType = [:]
        withUnsafeMutablePointer(&dict) { ctx in
            CGPDFDictionaryApplyFunction(self, f, ctx)
        }
        return dict
    }
    
    subscript(dictionary key: String) -> CGPDFDictionaryRef? {
        return key.withCString { ckey in
            var value = CGPDFDictionaryRef()
            if withUnsafeMutablePointer(&value, { return CGPDFDictionaryGetDictionary(self, ckey, $0) }) {
                return value
            } else {
                return nil
            }
        }
    }
    
    subscript(string key: String) -> String? {
        return key.withCString { ckey in
            var value = CGPDFStringRef()
            if withUnsafeMutablePointer(&value, { return CGPDFDictionaryGetString(self, ckey, $0) }) {
                if let string = CGPDFStringCopyTextString(value) {
                    return string as String
                }
            }
            return nil
        }
    }
    
    public subscript(key: String) -> CGPDFObjectRef? {
        return key.withCString { ckey in
            var value = CGPDFObjectRef()
            if withUnsafeMutablePointer(&value, { return CGPDFDictionaryGetObject(self, ckey, $0) }) {
                return value
            } else {
                return nil
            }
        }
    }
    
    func outlines() -> AnyGenerator<OutlineElement> {
        var ctx = self[dictionary: "First"]
        var stack = [CGPDFDictionaryRef]()
        return anyGenerator {
            guard let c = ctx else {
                return nil
            }

            if let first = c[dictionary: "First"] {
                stack.append(c)
                ctx = first
            } else if let nx = c[dictionary: "Next"] {
                ctx = nx
            } else if let lst = stack.last {
                stack.removeLast()
                ctx = lst[dictionary: "Next"]
            } else {
                ctx = nil
            }

            return OutlineElement(title: c[string: "Title"] ?? "", level: stack.count, destination: c[string: "Dest"] ?? "")
        }
    }
}
