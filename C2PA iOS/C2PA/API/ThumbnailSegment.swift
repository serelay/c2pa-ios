//
//  ThumbnailSegment.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation

public struct ThumbnailSegment: Codable {
    // Which of the jumbf segments to insert content into
    public let index: Int
    // The insertion point from start of this jumbf segment
    public let start: Int
    // How many bytes to insert
    public let length: Int
}
