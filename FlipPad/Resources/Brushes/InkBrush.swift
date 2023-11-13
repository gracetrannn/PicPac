//
//  InkBrush.swift
//  FlipPad
//
//  Created by Alex on 28.02.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import Foundation

class InkBrush {
    
    /**
     Returns texture image path
     
     - Parameter hardness determines how hard are brush edges
     */
    class func texturePathFor(hardness: Double) -> String? {
        var brushNumber = Int(hardness)
        var textureFileName = ""
        // Correct bounds
//        if(brushNumber == 1){
//            textureFileName = "Ink_1"
//        }else{
            brushNumber = min(max(1, 11 - brushNumber), 10)
            textureFileName = "Ink-\(brushNumber)"
//        }
        return Bundle.main.path(forResource: textureFileName, ofType: "png")
    }
    
    static func texturePath(with softness: Int) -> String? {
        let result = min(max(0, softness), 10)
        let name = "Ink_\(result)"
        return Bundle.main.path(forResource: name, ofType: "png")
    }
}
