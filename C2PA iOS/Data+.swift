//
//  Data+.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import Foundation

extension Data {
//    struct HexEncodingOptions: OptionSet {
//        let rawValue: Int
//        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
//    }
//
//    func hexEncodedString(options: HexEncodingOptions = []) -> String {
//        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
//        return map { String(format: format, $0) }.joined()
//    }
    
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
