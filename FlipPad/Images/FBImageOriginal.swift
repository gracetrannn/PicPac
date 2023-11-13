//
//  FBOriginalImage.swift
//  FlipPad
//
//  Created by zuzex on 11.10.2021.
//  Copyright © 2021 Alex. All rights reserved.
//

import Foundation

@objc class FBImageOriginal: NSObject {
    @objc  var buffer = NSData()
    
    @objc  var width: Int = 0
    @objc  var height: Int = 0
    
    @objc  var pixelBits: Int = 32
    
    private override init() {
        super.init()
    }
    
    @objc convenience init?(imageData: NSData?, width: Int, height: Int, pixelBits: Int) {
        guard let imageData = imageData, width != 0, height != 0 else {
            return nil
        }

        self.init(imageDataBuffer: imageData, width:width, height:height, pixelBits:pixelBits)
    }
    
    private init?(imageDataBuffer: NSData, width: Int, height: Int, pixelBits: Int) {
        self.buffer = imageDataBuffer
        self.width = width
        self.height = height
        self.pixelBits = pixelBits
    }
}

extension FBImageOriginal {
    
    @objc var size: CGSize {
        return CGSize(width: CGFloat(self.width), height: CGFloat(self.height))
    }
    
}
