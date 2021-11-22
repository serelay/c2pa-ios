//
//  ThumbnailUtil.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

public class ThumbnailUtil {

    /// Creates a thumbnail jpeg from the source jpeg which has baked-in EXIF transform applied
    /// and a dimension limit of 1024 pixels.
    /// - Parameters:
    /// - bytes The source JPEG as bytes to create a thumbnail of
    /// - Returns:The thumbnail JPEG data.
    public static func getReproducibleJPEGThumbnail(bytes: Data) -> Data {
        // print("Thumbnail input sha: \(SRLSHACal.shared.sha256(data: bytes))")
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(bytes as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
        else {
            fatalError()
        }
        let jpegData = UIImage(cgImage: image).jpegData(compressionQuality: 0.8)!
        // For debugging
        // try! jpegData.write(to: URL(fileURLWithPath: "/Users/<youruser>/Desktop/ios_thumbnail.jpg"))
        return jpegData
    }
    
    /// Creates a SHA256 hash, represented as a Base64 string
    /// - Parameters:
    /// - messageData The data to hash.
    /// - returns: Base64 encoded SHA256 hash
    static func hashOfBytes(messageData: Data) -> String {
        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes { (digestBytes) -> Bool in
            messageData.withUnsafeBytes { (messageBytes) -> Bool in
                CC_SHA256(messageBytes.baseAddress, CC_LONG(messageData.count), digestBytes.bindMemory(to: UInt8.self).baseAddress)
                return true
            }
        }
        
        return digestData.base64EncodedString()
    }
}
