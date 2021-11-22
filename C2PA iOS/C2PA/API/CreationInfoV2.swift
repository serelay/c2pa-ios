//
//  CreationInfoV2.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation

public struct CreationInfoV2: Codable {
    // Array of Base64 encoded strings
    public let jumbfs: [String]
    // Base64 encoded string
    public let xmp: String
    // Information for where client inserts thumbnail bytes
    public let thumbnailSegments: [ThumbnailSegment]
}
