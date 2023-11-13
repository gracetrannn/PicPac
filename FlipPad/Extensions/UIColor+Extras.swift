//
//  UIColor+Extras.swift
//  FlipPad
//
//  Created by Alex on 2/26/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import UIKit

extension UIColor {
    static let separatorColor = UIColor(red: 0.667, green: 0.667, blue: 0.667, alpha: 1.0)
    static let selectionColor = UIColor(red: 0.964, green: 1.0, blue: 0.817, alpha: 1.0)
}

extension FBColor {
    
    @objc var hex: String {
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
