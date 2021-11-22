//
//  C2PAFileHelper.swift
//  Serelay
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation
import CommonCrypto

class C2PAFileHelper {
    static let XMP_START = "http://ns.adobe.com/xap/1.0/"
    
    /// Retrieves information that the server needs from the file
    /// - Parameters:
    /// - fileData: The original file full JPEG byte array
    static func getInfoForFile(fileData: Data) -> AssetInfo {
        let thumbnailJpeg = ThumbnailUtil.getReproducibleJPEGThumbnail(bytes: fileData)
        let thumbnailHash = ThumbnailUtil.hashOfBytes(messageData: thumbnailJpeg)
        let thumbnailSize: Int = thumbnailJpeg.count
        
        let inputStream = InputStream(data: fileData)
        inputStream.open()
        let jumbfInsertionPoint = C2PAFileHelper.findJumbfInsertionPoint(inputStream)
        
        let assetHash = ThumbnailUtil.hashOfBytes(messageData: fileData)
        
        return AssetInfo(
            assetHash: assetHash,
            thumbnailHash: thumbnailHash,
            thumbnailAssertionLength: thumbnailSize,
            jumbfInsertionPoint: jumbfInsertionPoint
        )
    }
    
    /// Retrieves information that the server needs from the file
    /// JUMBF is inserted before the first of any existing APP11 marker
    /// - Parameters:
    /// - stream: The stream for reading the original file sequentially
    static func findJumbfInsertionPoint(_ stream: InputStream) -> Int {
        let APP11_MARKER = [0xFF, 0xEB]
        var marker = [UInt8](repeating: 0, count: 2)
        var segmentLength = [UInt8](repeating: 0, count: 2)
        
        var offset = 2
        stream.read(&marker, maxLength: 2)
        
        stream.read(&marker, maxLength: 2)
        stream.read(&segmentLength, maxLength: 2)

        while marker[1] >= 0xE0 && marker[1] < APP11_MARKER[1] {
            let contentLength = lengthFromBytes(bytes: segmentLength)

            // Skip XMP for case of Idem photos...
            var toSkip = contentLength
            if marker[0] == 0xFF && marker[1] == 0xE1 {
                // Could be XMP
                if contentLength > XMP_START.count {
                    var buffer = [UInt8](repeating: 0, count: XMP_START.count)
                    stream.read(&buffer, maxLength: XMP_START.count)
                    let content = String(bytes: buffer, encoding: .utf8)
                    if content == XMP_START {
                        // We're in an XMP block
                        // We discount the marker, length and content from the offset (ahead of time)
                        offset -= 4
                        offset -= contentLength
                    }
                    // We've read the XMP_START.length now, so need to reduce our skipped by that
                    toSkip -= XMP_START.count
                }
            }
            // Skip rest of this marker
            var bytes = [UInt8](repeating: 0, count: toSkip)
            stream.read(&bytes, maxLength: toSkip)
            
            offset += 4 // marker + length
            offset += contentLength
            
            stream.read(&marker, maxLength: 2)
            stream.read(&segmentLength, maxLength: 2)
        }
        
        return offset
    }
       
    /// Retrieve the integer conversion of 2 bytes from the data, in big endian.
    /// - Parameters:
    /// - bytes: The byte array to read from
    /// - Returns: The integer conversion
    private static func lengthFromBytes(bytes: [UInt8]) -> Int {
        return Int(Data(bytes: bytes, count: 2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian) - 2
    }

}
