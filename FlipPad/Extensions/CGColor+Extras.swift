//
//  CGColor+Extras.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/6/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import Foundation

extension CGColor {
    
    func isLike(_ color: CGColor) -> Bool {
        guard let originalColor = self.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
              let otherColor = color.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil) else {
            return false
        }
        // 0
        let r0 = (originalColor.components?[0] ?? 0.0)
        let g0 = (originalColor.components?[1] ?? 0.0)
        let b0 = (originalColor.components?[2] ?? 0.0)
        let a0 = (originalColor.components?[3] ?? 0.0)
        // 1
        let r1 = (otherColor.components?[0] ?? 0.0)
        let g1 = (otherColor.components?[1] ?? 0.0)
        let b1 = (otherColor.components?[2] ?? 0.0)
        let a1 = (otherColor.components?[3] ?? 0.0)
        //
        let dr = abs(r0 - r1)
        let dg = abs(g0 - g1)
        let db = abs(b0 - b1)
        let da = abs(a0 - a1)
        //
        return (dr < 0.005) && (dg < 0.005) && (db < 0.005) && (da < 0.005)
    }
    
    @available(iOS 13.0, *)
    static var clearColor: CGColor { .init(red: 0, green: 0, blue: 0, alpha: 0) }
    
}
