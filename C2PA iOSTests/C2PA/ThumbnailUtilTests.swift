//
//  ThumbnailUtilTests.swift
//  SerelayTests
//
//  Created by Ian Field on 29/01/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import XCTest
@testable import C2PA_iOS

class ThumbnailUtilTests: XCTestCase {
    var testImageUrl: URL!
    
    override func setUpWithError() throws {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "srl_test_image", ofType: "jpg")!
        testImageUrl = URL(fileURLWithPath: path)
    }
    
    override func tearDownWithError() throws {
    }
    
    func testCreatesReproducibleThumnbnail() {
        let data = try! Data(contentsOf: testImageUrl)
        let jpegData = ThumbnailUtil.getReproducibleJPEGThumbnail(bytes: data)
        
        let hash = ThumbnailUtil.hashOfBytes(messageData: jpegData)
        XCTAssertEqual(hash, "bfOZu8JzgQy5miraGM1MmJNTGHFD/3dkCAbE9wn9JD4=")
    }
    
}
