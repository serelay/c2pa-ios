//
//  APPNWriter.swift
//  C2PA iOS
//
//  Created by Ian Field on 23/10/2020.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation

public typealias Marker = [UInt8] // 2
public typealias Length = [UInt8] // 2
public typealias Content = [UInt8]
public typealias SegmentHeader = (Marker, Length)
public typealias MarkerContent = (Marker, Content)

/// App segments are inserted before existing headers. So we'll read up until the start of the following segment, if that segment
/// is higher or the same as the one we're looking to insert then we perform the insertion, otherwise we copy the contents.
/// E.g. Original[A, B, C] inserting A0 would become: [A0, A, B, C] and not [A, A0, B, C]
@objc(APPNWriter)
public class APPNWriter: NSObject {
    public static let APP1_MARKER: Marker = [0xFF, 0xE1]
    public static let APP11_MARKER: Marker = [0xFF, 0xEB]
    
    public func insertAppNContent(
        originalUrl: URL,
        destinationUrl: URL,
        content: [MarkerContent],
        includeLength: Bool
    ) {
        let original = InputStream(url: originalUrl)!
        original.open()
        let destination = OutputStream(url: destinationUrl, append: false)!
        destination.open()
        
        var marker = [UInt8](repeating: 0, count: 2)
        var segmentLength = [UInt8](repeating: 0, count: 2)
        
        // JPEG header
        original.read(&marker, maxLength: 2)
        destination.write(marker, maxLength: 2)
        
        // APP0 segment marker
        original.read(&marker, maxLength: 2)
        original.read(&segmentLength, maxLength: 2)
        
        for markerContent in content {
            
            while
                marker[1] < markerContent.0[1] &&
                    marker[1] >= 0xE0 &&
                    marker[1] <= 0xEF
            {
                let count = Int(Data(bytes: segmentLength, count: 2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian) - 2
                var content = [UInt8](repeating: 0, count: count)
                
                original.read(&content, maxLength: count)
                
                if !(String(bytes: content, encoding: .utf8)?.starts(with: "http://ns.adobe.com/xap/1.0/") == true) {
                    destination.write(marker, maxLength: 2)
                    destination.write(segmentLength, maxLength: 2)
                    destination.write(content, maxLength: count)
                }
                original.read(&marker, maxLength: 2)
                original.read(&segmentLength, maxLength: 2)
            }
            
            writeContent(
                destination: destination,
                markerContent: markerContent,
                includeLength: includeLength
            )
        }
        
        destination.write(marker, maxLength: 2)
        destination.write(segmentLength, maxLength: 2)
        
        // Write out remainder of file
        let size = 2000000
        var buffer = [UInt8](repeating: 0, count: size)
        while original.hasBytesAvailable {
            let read = original.read(&buffer, maxLength: size)
            if read >= 0 {
                destination.write(&buffer, maxLength: read)
            }
        }
        
        original.close()
        destination.close()
    }
    
    private func writeContent(
        destination: OutputStream,
        markerContent: MarkerContent,
        includeLength: Bool
    ) {
        let marker = markerContent.0
        let content = markerContent.1
        let contentLength = markerContent.1.count
        destination.write(marker, maxLength: 2)

        if includeLength {
            var length = (UInt16(contentLength) + 2).bigEndian
            destination.write(Data(bytes: &length, count: 2).bytes, maxLength: 2)
        }
        destination.write(content, maxLength: contentLength)
    }
    
    public func insertAppNContentWithThumbnail(
        originalUrl: URL,
        destinationUrl: URL,
        content: [MarkerContent],
        includeLength: Bool,
        thumbnailJpeg: Data,
        thumbnailSegments: [ThumbnailSegment]
    ) {
        // Must not reorder here because the indexes must be preserved for thumbnail insertion
        let original = InputStream(url: originalUrl)!
        original.open()
        let destination = OutputStream(url: destinationUrl, append: false)!
        destination.open()
        
        var marker = [UInt8](repeating: 0, count: 2)
        var segmentLength = [UInt8](repeating: 0, count: 2)
        
        // JPEG header
        original.read(&marker, maxLength: 2)
        destination.write(marker, maxLength: 2)
        
        // APP0 segment marker
        original.read(&marker, maxLength: 2)
        original.read(&segmentLength, maxLength: 2)

        var offset = 0

        for (index, markerContent) in content.enumerated() {
            
            while
                marker[1] < markerContent.0[1] &&
                marker[1] >= 0xE0 &&
                marker[1] <= 0xEF
            {
                let count = Int(Data(bytes: segmentLength, count: 2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian) - 2
                var content = [UInt8](repeating: 0, count: count)
                
                original.read(&content, maxLength: count)
                
                if !(String(bytes: content, encoding: .utf8)?.starts(with: "http://ns.adobe.com/xap/1.0/") == true) {
                    destination.write(marker, maxLength: 2)
                    destination.write(segmentLength, maxLength: 2)
                    destination.write(content, maxLength: count)
                }
                original.read(&marker, maxLength: 2)
                original.read(&segmentLength, maxLength: 2)
            }
            
            let first = markerContent.0
            // We need to augment the content with our thumbnail data here
            var second: Content?
            if markerContent.0[0] == 0xFF && markerContent.0[1] == 0xEB {
                if let segment = thumbnailSegments.first(where: { (it) -> Bool in
                    it.index == index - 1
                }) {
                    second = augmentContents(original: markerContent.1, segment: segment, thumbnailJpeg: thumbnailJpeg, offset: offset)
                    offset += segment.length
                }
            }

            writeContent(
                destination: destination,
                markerContent: (first, second ?? markerContent.1), // either the injected thumbnail or the untouched server content
                includeLength: includeLength
            )
        }
        
        destination.write(marker, maxLength: 2)
        destination.write(segmentLength, maxLength: 2)
        
        // Write out remainder of file
        let size = 2000000
        var buffer = [UInt8](repeating: 0, count: size)
        while original.hasBytesAvailable {
            let read = original.read(&buffer, maxLength: size)
            if read >= 0 {
                destination.write(&buffer, maxLength: read)
            }
        }
        
        original.close()
        destination.close()
    }

    
    public func augmentContents(
        original: Content,
        segment: ThumbnailSegment,
        thumbnailJpeg: Data,
        offset: Int
    ) -> Content {
        let start = Array(original[0..<segment.start])
        var middle: [UInt8]
        if offset + segment.length > thumbnailJpeg.count {
            // prevent crash if current thumbnail is different length to processing-time thumbnail
            // blank out with 0's
            let end = offset + segment.length
            // Write the rest of the thumbnail JPEG that we can
            middle = thumbnailJpeg.subdata(in: offset..<thumbnailJpeg.count).bytes
            // Pad the remainder with 0's
            middle += [UInt8](repeating: 0, count: segment.length - middle.count)
            // Underlying C2PA will fail validation on the thumbnail portion, but is visually there.
            
            print("Thumbnail insertion error: Insertion is padded. Thumbnail was shorter by: \(end - thumbnailJpeg.count) bytes")
        } else {
            middle = thumbnailJpeg.subdata(in: offset..<(offset + segment.length)).bytes
        }
        let end = Array(original[segment.start..<original.count])
        return start + middle + end
    }
}
