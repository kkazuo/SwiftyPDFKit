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

public extension CGPDFDocumentRef {

    public var numberOfPages: Int {
        return CGPDFDocumentGetNumberOfPages(self)
    }

    public var catalog: PDFDictionaryType {
        return CGPDFDocumentGetCatalog(self).shallowCopy()
    }

    public var info: PDFDictionaryType {
        return CGPDFDocumentGetInfo(self).shallowCopy()
    }

    public var title: String? {
        return infoString("Title")
    }

    public var author: String? {
        return infoString("Author")
    }

    public var subject: String? {
        return infoString("Subject")
    }

    public var keywords: String? {
        return infoString("Keywords")
    }

    public var creator: String? {
        return infoString("Creator")
    }

    public var producer: String? {
        return infoString("Producer")
    }

    public var creationDate: NSDate? {
        return infoDate("CreationDate")
    }

    public var modDate: NSDate? {
        return infoDate("ModDate")
    }

    public var trapped: String? {
        let info = CGPDFDocumentGetInfo(self)
        if info == nil {
            return nil
        }
        return info[name: "Trapped"]
    }

    public var version: PDFVersion {
        var major: Int32 = 0
        var minor: Int32 = 0
        withUnsafeMutablePointers(&major, &minor) {
            CGPDFDocumentGetVersion(self, $0, $1)
        }
        return PDFVersion(major: major, minor: minor)
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
        guard
            let ol = catalog[dictionary: "Outlines"],
            let pages = catalog[dictionary: "Pages"] else
        {
            return []
        }

        let pageIndices = pages.pageIndices
        let nameTable = catalog[dictionary: "Names"]?[dictionary: "Dests"]

        return ol.outlines(pageIndices, nameTable)
    }

    public var allowsCopying: Bool {
        return CGPDFDocumentAllowsCopying(self)
    }

    public var allowsPrinting: Bool {
        return CGPDFDocumentAllowsPrinting(self)
    }

    public var isEncrypted: Bool {
        return CGPDFDocumentIsEncrypted(self)
    }

    public var isUnlocked: Bool {
        return CGPDFDocumentIsUnlocked(self)
    }

    public func unlock(password: String) -> Bool {
        return password.withCString { CGPDFDocumentUnlockWithPassword(self, $0) }
    }

    private func infoString(key: String) -> String? {
        let info = CGPDFDocumentGetInfo(self)
        if info == nil {
            return nil
        }
        return info[string: key]
    }

    private func infoDate(key: String) -> NSDate? {
        let info = CGPDFDocumentGetInfo(self)
        if info == nil {
            return nil
        }
        return info[date: key]
    }
}
