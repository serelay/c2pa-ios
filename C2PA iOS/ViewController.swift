//
//  ViewController.swift
//  C2PA iOS
//
//  Created by Ian Field on 08/11/2021.
//  Copyright © 2021 Serelay Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "srl_test_image", ofType: "jpg")!
        let originalFile = URL(fileURLWithPath: path)
        
        // Information required by the server to create the asset
        prepareServerInfo(originalFile)
        
        let c2paImage = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("c2pa.jpg")
        let c2paImageLocalThumb = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("c2paLocalThumb.jpg")
        
        
        // ## Either:
        // This version the JUMBF provided by the server is to include the thumbnail
        fullUploadVersion(original: originalFile, output: c2paImage)
        
        // ## Or:
        localThumbailVersion(original: originalFile, output: c2paImageLocalThumb)
        
        // c2pa.jpg - Version with asset information, internal thumbnail provided by server
        // c2paLocalThumb.jpg - Version with partial thumbnail data inserted locally
        
        // These can be viewed in App bundle download or in simulator storage
    }
    
    ///
    /// Obtain real data for use by the server when generating C2PA asset information
    /// Uses srl_test_image.jpg
    func prepareServerInfo(_ input: URL) {
        let fileData = try! Data(contentsOf: input)
        let serverInfo = C2PAFileHelper.getInfoForFile(fileData: fileData)
        
//        AssetInfo(
//            assetHash: "tDsLwbKP2Fe8ke67HGPFRWk7+OJ03atkkutPk/HFjhI=",
//            thumbnailHash: "bfOZu8JzgQy5miraGM1MmJNTGHFD/3dkCAbE9wn9JD4=",
//            thumbnailAssertionLength: 257019,
//            jumbfInsertionPoint: 854,
//            xmpInsertionPoint: 2
//        )
        print("\(serverInfo)")
    }
    
    func fullUploadVersion(original: URL, output: URL) {
        // NB these are placeholders, the information should be provided by the server.
        let creationInfo = CreationInfo(
            jumbfs: ["TXlKdW1iZkV4YW1wbGU="], // [MyJumbfExample] as base64
            xmp: "TXlFeGFtcGxlWE1Q" // MyExampleXMP as Base64
        )

        C2PACreator.createC2paCompliantFile(
            original: original,
            output: output,
            info: creationInfo
        )
    }
     
    func localThumbailVersion(original: URL, output: URL) {
        let creationInfo = CreationInfoV2(
            jumbfs: ["TXlKdW1iZkV4YW1wbGU="], // [MyJumbfExample] as base64
            xmp: "TXlFeGFtcGxlWE1Q", // MyExampleXMP as Base64
            thumbnailSegments: [
                // This is a trivial thumbnail example.
                // Insert 24 bytes of thumbnail in jumbfs[0], from 0 bytes in
                // e.g. FFD8FFE1 006A4578 69660000 4D4D002A 00000008 00040100
                ThumbnailSegment(index: 0, start: 0, length: 24)
                // i.e. [First24 bytes of thumbnail, MyJumbfExample]
            ]
        )
        
        C2PACreator.createC2paCompliantFileWithThumbnail(
            original: original,
            output: output,
            info: creationInfo
        )
     }

}

