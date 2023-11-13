//
//  ImageTransform.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 2/20/22.
//  Copyright © 2022 Alex. All rights reserved.
//

import Foundation
import opencv2

@objc class ImageTransform: NSObject {
    
    let src: [Point2f]
    let dst: [Point2f]
    
    init(src: [Point2f], dst: [Point2f]) {
        self.src = src
        self.dst = dst
        
        super.init()
    }
    
}
