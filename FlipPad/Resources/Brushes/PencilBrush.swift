//
//  PencilBrush.swift
//  FlipPad
//
//  Created by Andrey Rybalkin on 24.11.2022.
//  Copyright © 2022 Alex. All rights reserved.
//

import Foundation

class PencilBrush {
        
    static func texturePath(with softness: Int) -> String? {
        let result = min(max(0, softness), 10)
        let name = "pencil_\(result)"
        return Bundle.main.path(forResource: name, ofType: "png")
    }
}
