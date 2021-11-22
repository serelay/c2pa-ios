//
//  C2PACreator.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation

/// A class to assist in the creation of the C2PA assets with V2 APIs, which requires the application to create the file locally with thumbnail data.
/// This approach uses much less bandwith, and has significant privacy benefit compared to the original approach, and should be used.
/// Convenience methods for the original approach are not provided to discourage its use.
public class C2PACreator {
    
    /// Create a C2PA version of the original file with the thumbnail inserted client-side.
    /// - Parameters:
    ///   - original: The URL of the original file which forms the basis of the new C2PA version.
    ///   - output: The URL to write the file to. This should be a temporary URL internal to the application. Write permission is assumed.
    ///   - info: The creation information for the C2PA asset creation. This will have sections inserted with thumbnail data accordingly.
    public static func createC2paCompliantFileWithThumbnail(original: URL, output: URL, info: CreationInfoV2) {
        let app11s = info.jumbfs.map { MarkerContent(APPNWriter.APP11_MARKER, [UInt8](Data(base64Encoded: $0)!)) }
        let xmp = [UInt8](Data(base64Encoded: info.xmp)!)
        let content = [MarkerContent(APPNWriter.APP1_MARKER, xmp)] + app11s
        let thumbnailJpeg = try! ThumbnailUtil.getReproducibleJPEGThumbnail(bytes: Data(contentsOf: original))
        APPNWriter().insertAppNContentWithThumbnail(
                originalUrl: original,
                destinationUrl: output,
                content: content,
                includeLength: true,
                thumbnailJpeg: thumbnailJpeg,
                thumbnailSegments: info.thumbnailSegments)
    }
    
    /// Create a C2PA version of the original file with the thumbnail inserted server-side
    /// - Parameters:
    ///   - original: The URL of the original file which forms the basis of the new C2PA version.
    ///   - output: The URL to write the file to. This should be a temporary URL internal to the application. Write permission is assumed.
    ///   - info: The creation information for the C2PA asset creation. This will be inserted verbatim.
    public static func createC2paCompliantFile(original: URL, output: URL, info: CreationInfo) {
        let app11s = info.jumbfs.map { MarkerContent(APPNWriter.APP11_MARKER, [UInt8](Data(base64Encoded: $0)!)) }
        let xmp = [UInt8](Data(base64Encoded: info.xmp)!)
        let content = [MarkerContent(APPNWriter.APP1_MARKER, xmp)] + app11s
        
        APPNWriter().insertAppNContent(
            originalUrl: original,
            destinationUrl: output,
            content: content,
            includeLength: true
        )
    }
}
