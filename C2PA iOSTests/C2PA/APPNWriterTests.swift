//
//  APPNWriterTests.swift
//  SerelayTests
//
//  Created by Ian Field on 26/10/2020.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import XCTest
@testable import C2PA_iOS

class APPNWriterTests: XCTestCase {
    var writer: APPNWriter!
    var url: URL!
    let directory: String = NSTemporaryDirectory()
    
    override func setUpWithError() throws {
        writer = APPNWriter()
    }

    override func tearDownWithError() throws {
    }
    
    func getURLFromResource(fileName: String, ext: String) -> URL {
        let bundle = Bundle(for: type(of: self))
        return bundle.url(forResource: fileName, withExtension: ext)!
    }
    
    func testInsertion() throws {
        let contentToWrite = "Ian Rocks"
        let markerContents: [MarkerContent] = [
            (APPNWriter.APP1_MARKER, [UInt8](contentToWrite.utf8))
        ]
        
        let inputUrl = getURLFromResource(fileName: "lena_with_APP0_APP1_APP10_APP11_APP12", ext: "jpg")
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("lena_injected_content.jpg")
        writer.insertAppNContent(
            originalUrl: inputUrl,
            destinationUrl: outputUrl,
            content: markerContents,
            includeLength: true
        )
        print("\(outputUrl.path)")
        let attr: [FileAttributeKey: Any]? = try FileManager.default.attributesOfItem(atPath: outputUrl.path)
        // Original size + 2 marker + 2 length + content length
        XCTAssertEqual(Int(attr?[.size] as! UInt64), 30265 + 2 + 2 + contentToWrite.count)
    }
    
    func testCanWriteWithinExistingAppSegments() throws {
        let markerContents: [MarkerContent] = [
            (APPNWriter.APP11_MARKER, [UInt8]("Ian Rocks".utf8))
        ]
        
        let inputUrl = getURLFromResource(fileName: "lena_with_APP0_APP1_APP10_APP11_APP12", ext: "jpg")
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("lena_injected_content.jpg")
        writer.insertAppNContent(
            originalUrl: inputUrl,
            destinationUrl: outputUrl,
            content: markerContents,
            includeLength: true
        )
        
        let inputStream = InputStream(url: outputUrl)!
        inputStream.open()
        var marker = [UInt8](repeating: 0, count: 2)
        var segmentLength = [UInt8](repeating: 0, count: 2)
        
        inputStream.read(&marker, maxLength: 2)
        
        XCTAssertEqual(marker[0], 0xFF)
        XCTAssertEqual(marker[1], 0xD8)
        
        let expectedSegmentMarkers: [UInt8] = [0xE0, 0xE1, 0xEA, 0xEB, 0xEB, 0xEC]
        
        for i in expectedSegmentMarkers {
            inputStream.read(&marker, maxLength: 2)
            inputStream.read(&segmentLength, maxLength: 2)
            XCTAssertEqual(marker[0], 0xFF)
            XCTAssertEqual(marker[1], i)
            
            let length = lengthFromBytes(bytes: segmentLength)
            var buffer = [UInt8](repeating: 0, count: length)
            inputStream.read(&buffer, maxLength: length)
        }
        inputStream.close()
    }
    
    func testCanInsertMultipleSegments() {
        let markerContents: [MarkerContent] = [
            (APPNWriter.APP1_MARKER, [UInt8]("Whassup".utf8)),
            (APPNWriter.APP11_MARKER, [UInt8]("Ian Rocks".utf8))
        ]
        
        let inputUrl = getURLFromResource(fileName: "lena_with_APP0_APP1_APP10_APP11_APP12", ext: "jpg")
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("lena_injected_content.jpg")
        writer.insertAppNContent(
            originalUrl: inputUrl,
            destinationUrl: outputUrl,
            content: markerContents,
            includeLength: true
        )
        
        let inputStream = InputStream(url: outputUrl)!
        inputStream.open()
        var marker = [UInt8](repeating: 0, count: 2)
        var segmentLength = [UInt8](repeating: 0, count: 2)
        
        inputStream.read(&marker, maxLength: 2)
        
        XCTAssertEqual(marker[0], 0xFF)
        XCTAssertEqual(marker[1], 0xD8)
        
        let expectedSegmentMarkers: [UInt8] = [0xE0, 0xE1, 0xE1, 0xEA, 0xEB, 0xEB, 0xEC]
        
        for i in expectedSegmentMarkers {
            inputStream.read(&marker, maxLength: 2)
            inputStream.read(&segmentLength, maxLength: 2)
            XCTAssertEqual(marker[0], 0xFF)
            XCTAssertEqual(marker[1], i)
            
            let length = lengthFromBytes(bytes: segmentLength)
            var buffer = [UInt8](repeating: 0, count: length)
            inputStream.read(&buffer, maxLength: length)
        }
        inputStream.close()
    }
    
    func testStripsExistingXMP() {
        let markerContents: [MarkerContent] = [
            (APPNWriter.APP11_MARKER, [UInt8]("Ian Rocks".utf8))
        ]
        
        let inputUrl = getURLFromResource(fileName: "srl_test_image", ext: "jpg")
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_without_xmp.jpg")
        print(outputUrl)
        
        writer.insertAppNContent(
            originalUrl: inputUrl,
            destinationUrl: outputUrl,
            content: markerContents,
            includeLength: true
        )
        
        let attr = try! FileManager.default.attributesOfItem(atPath: outputUrl.path)
        let fileSize = attr[FileAttributeKey.size] as! Int // UInt64
        
        let originalLength = 1_799_561
        // XMP size marker is: 028F, 655
        let expectedLength = originalLength - 655 + "Ian Rocks".count + 2
        XCTAssertEqual(fileSize, expectedLength)
    }
    
    func testStripsNothingIfNoXMP() {
        let markerContents: [MarkerContent] = [
            (APPNWriter.APP11_MARKER, [UInt8]("Ian Rocks".utf8))
        ]
        
        let inputUrl = getURLFromResource(fileName: "capture_s8", ext: "jpg")
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("capture_s8_without_xmp.jpg")
        
        print(outputUrl)
        
        writer.insertAppNContent(
            originalUrl: inputUrl,
            destinationUrl: outputUrl,
            content: markerContents,
            includeLength: true
        )
        
        let attr = try! FileManager.default.attributesOfItem(atPath: outputUrl.path)
        let fileSize = attr[FileAttributeKey.size] as! Int // UInt64
        
        let originalLength = 3_655_699
        let expectedLength = originalLength + 2 + "Ian Rocks".count + 2
        XCTAssertEqual(fileSize, expectedLength)

    }
    
    func testCanInsertThumbnailData() {
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testImageWithThumbnail.jpg")
        
        let markers = [
            MarkerContent(APPNWriter.APP1_MARKER, Array("Whatsup".utf8)),
            MarkerContent(APPNWriter.APP11_MARKER, Array("IM_A_CAIBLOCK".utf8))
        ]
        
        let jpeg = Data(Array("ThumbnailPlaceholderThumbnailPlaceholderThumbnailPlaceholder".utf8))
        
        let segments = [
            ThumbnailSegment(index: 0, start: 3, length: 44)
        ]
        
        writer.insertAppNContentWithThumbnail(
            originalUrl: getURLFromResource(fileName: "srl_test_image", ext: "jpg"),
            destinationUrl: outputUrl, content: markers,
            includeLength: true,
            thumbnailJpeg: jpeg,
            thumbnailSegments: segments
        )
        
        let attr = try! FileManager.default.attributesOfItem(atPath: outputUrl.path)
        let fileSize = attr[FileAttributeKey.size] as! Int // UInt64
        
        let originalLength = 1_799_561
        XCTAssertGreaterThan(fileSize, originalLength - 657)
        var extra = 0
        markers.forEach { (_, content: Content) in
            extra += 2 + content.count + 2
        }
        segments.forEach { (segment) in
            extra += segment.length
        }
        // original size + extra inserted - existing xmp size (inc marker)
        XCTAssertEqual(fileSize, originalLength + extra - 657)
    }
    
    func testCanInsertThumbnailDataMultiSegment() {
        let outputUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("testImageWithThumbnail.jpg")
        
        let markers = [
            MarkerContent(APPNWriter.APP1_MARKER, Array("Whatsup".utf8)),
            MarkerContent(APPNWriter.APP11_MARKER, Array("IM_A_CAIBLOCK".utf8)),
            MarkerContent(APPNWriter.APP11_MARKER, Array("IM_ALSO_A_CAIBLOCK".utf8))
        ]
        
        let jpeg = Data(Array("ThumbnailPlaceholderThumbnailPlaceholderThumbnailPlaceholder".utf8))
        
        let segments = [
            ThumbnailSegment(index: 0, start: 3, length: 44),
            ThumbnailSegment(index: 1, start: 4, length: 3)
        ]
        
        writer.insertAppNContentWithThumbnail(
            originalUrl: getURLFromResource(fileName: "srl_test_image", ext: "jpg"),
            destinationUrl: outputUrl, content: markers,
            includeLength: true,
            thumbnailJpeg: jpeg,
            thumbnailSegments: segments
        )
        
        let attr = try! FileManager.default.attributesOfItem(atPath: outputUrl.path)
        let fileSize = attr[FileAttributeKey.size] as! Int // UInt64
        
        let originalLength = 1_799_561
        XCTAssertGreaterThan(fileSize, originalLength - 657)
        var extra = 0
        markers.forEach { (_, content: Content) in
            extra += 2 + content.count + 2
        }
        segments.forEach { (segment) in
            extra += segment.length
        }
        // original size + extra inserted - existing xmp size (inc marker)
        XCTAssertEqual(fileSize, originalLength + extra - 657)
    }
    
    func test_augmentContents() {
        let jpeg = Data(bytes: Array(String(repeating: "A", count: 30).utf8), count: 30)
        let original = Array(String(repeating: "0", count: 10).utf8)
        
        let segment = ThumbnailSegment(index: 0, start: 10, length: 20)
        
        let result: Content = writer.augmentContents(
            original: original,
            segment: segment,
            thumbnailJpeg: jpeg,
            offset: 0
        )
        
        let expectation = Array(String(repeating: "0", count: 10).utf8) + Array(String(repeating: "A", count: 20).utf8)
        XCTAssertEqual(result, expectation)
    }
    
    func test_aughmentContents_padded() {
        let jpeg = Data(bytes: Array(String(repeating: "A", count: 10).utf8), count: 10)
        let original = Array(String(repeating: "1", count: 10).utf8)
        
        let segment = ThumbnailSegment(index: 0, start: 10, length: 20)
        
        let result: Content = writer.augmentContents(
            original: original,
            segment: segment,
            thumbnailJpeg: jpeg,
            offset: 0
        )
        
        let expectation = Array(String(repeating: "1", count: 10).utf8)
            + Array(String(repeating: "A", count: 10).utf8)
            + [UInt8](repeating: 0, count: 10)
        XCTAssertEqual(result, expectation)
    }
    
    private func lengthFromBytes(bytes: [UInt8]) -> Int {
        return Int(Data(bytes: bytes, count: 2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian) - 2
    }
}
