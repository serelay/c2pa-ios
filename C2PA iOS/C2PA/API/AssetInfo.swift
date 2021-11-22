//
//  AssetInfo.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation

public struct AssetInfo: Codable {
    public let assetHash: String
    public let thumbnailHash: String
    public let thumbnailAssertionLength: Int
    public let jumbfInsertionPoint: Int
    public let xmpInsertionPoint: Int = 2
}
