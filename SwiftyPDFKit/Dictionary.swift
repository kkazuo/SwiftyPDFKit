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
                
            case .Integer:
                var value = CGPDFInteger()
                if withUnsafeMutablePointer(&value, { CGPDFObjectGetValue(obj, .Integer, $0) }) {
                    dict[key] = value
                }
                
            case .Real: 0
                
            case .Name:
                var value: UnsafePointer<Int8> = nil
                if withUnsafeMutablePointer(&value, { CGPDFObjectGetValue(obj, .Name, $0) }) {
                    if let s = String.fromCString(value) {
                        dict[key] = s
                    }
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
                dict[key] = [AnyObject]()
                
            case .Dictionary:
                dict[key] = PDFDictionaryType()
                
            case .Stream:
                dict[key] = PDFDictionaryType()
            }
            
            UnsafeMutablePointer<PDFDictionaryType>(ctx).memory = dict
        }
        
        var dict: PDFDictionaryType = PDFDictionaryType()
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

    subscript(array key: String) -> CGPDFArrayRef? {
        return key.withCString { ckey in
            var value = CGPDFArrayRef()
            if withUnsafeMutablePointer(&value, { return CGPDFDictionaryGetArray(self, ckey, $0) }) {
                return value
            } else {
                return nil
            }
        }
    }

    subscript(integer key: String) -> Int? {
        return key.withCString { ckey in
            var value = CGPDFInteger()
            if withUnsafeMutablePointer(&value, { CGPDFDictionaryGetInteger(self, ckey, $0) }) {
                return value
            }
            return nil
        }
    }

    subscript(name key: String) -> String? {
        return key.withCString { ckey in
            var value = UnsafePointer<Int8>()
            if withUnsafeMutablePointer(&value, { CGPDFDictionaryGetName(self, ckey, $0) }) {
                if let s = String.fromCString(value) {
                    return s
                }
            }
            return nil
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
    
    subscript(key: String) -> CGPDFObjectRef? {
        return key.withCString { ckey in
            var value = CGPDFObjectRef()
            if withUnsafeMutablePointer(&value, { return CGPDFDictionaryGetObject(self, ckey, $0) }) {
                return value
            } else {
                return nil
            }
        }
    }
    
    func outlines(pageIndices: [CGPDFDictionaryRef : Int], _ nameTable: CGPDFDictionaryRef?) -> [OutlineElement] {
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

            guard let dest = c[string: "Dest"],
                let names = nameTable,
                let p = nameTableSearch(names, key: dest),
                let idx = pageIndices[p] else
            {
                return OutlineElement(title: "", level: 0, page: 0)
            }
            return OutlineElement(title: c[string: "Title"] ?? "", level: stack.count, page: idx)
        }.filter { $0.page != 0 }
    }
    
    var pageIndices: [CGPDFObjectRef : Int] {
        var indices = [CGPDFDictionaryRef : Int]()
        (_, indices) = self.pageIndicesAux(start: 1, indices: indices)
        return indices
    }
    
    private func pageIndicesAux(start start: Int, var indices: [CGPDFDictionaryRef : Int]) -> (Int, [CGPDFDictionaryRef : Int]) {
        guard let kids = self[array: "Kids"] else {
            return (start, indices)
        }
        let max = kids.count
        var st = start
        for var i = 0; i < max; i++ {
            guard let k = kids[dictionary: i], t = k[name: "Type"] else {
                continue
            }
            if t == "Page" {
                indices[k] = st++
            } else if t == "Pages" {
                (st, indices) = k.pageIndicesAux(start: st, indices: indices)
            }
        }
        return (st, indices)
    }
}

private func nameTableSearch(dict: CGPDFDictionaryRef, key: String) -> CGPDFDictionaryRef? {
    var dict = dict
    repeat {
        guard let kids = dict[array: "Kids"] where 0 < kids.count else {
            return nil
        }

        var min = 0
        var max = kids.count - 1
        var pivot = max / 2
        kids: repeat {
            guard let kid = kids[dictionary: pivot], order = nameTableOrder(kid, key: key) else {
                return nil
            }
            switch order {
            case NSComparisonResult.OrderedAscending:
                max = pivot - 1
                pivot = min + (max - min) / 2
            case NSComparisonResult.OrderedDescending:
                min = pivot + 1
                pivot = min + (max - min) / 2
            case NSComparisonResult.OrderedSame:
                if let p = namesSearch(kid, key: key) {
                    return p
                }
                dict = kid
                break kids
            }
        } while true
    } while true
}

private func nameTableOrder(dict: CGPDFDictionaryRef, key: String) -> NSComparisonResult? {
    guard let
        limits = dict[array: "Limits"],
        left = limits[string: 0],
        right = limits[string: 1] else {
            return nil
    }
    if key < left {
        return NSComparisonResult.OrderedAscending
    } else if right < key {
        return NSComparisonResult.OrderedDescending
    } else {
        return NSComparisonResult.OrderedSame
    }
}

private func namesSearch(dict: CGPDFDictionaryRef, key: String) -> CGPDFDictionaryRef? {
    guard let names = dict[array: "Names"] else {
        return nil
    }
    let count = names.count
    if count <= 0 || (count & 1) != 0 {
        return nil
    }

    var min = 0
    var max = count - 1
    var i = max / 2
    repeat {
        guard let name = names[string: i * 2] else {
            return nil
        }
        if key < name {
            max = i - 1
            i = min + (max - min) / 2
        } else if name < key {
            min = i + 1
            i = min + (max - min) / 2
        } else /*if name == key*/ {
            return names[dictionary: i * 2 + 1]?[array: "D"]?[dictionary: 0]
        }
    } while true
}
