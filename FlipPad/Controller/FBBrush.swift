//
//  FBBrush.swift
//  FlipPad
//
//  Created by Alex on 12.04.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import Foundation

@objc class FBBrush: NSObject {

    @objc let name: String
    @objc let previewName: String
    
    init(name: String, previewName: String) {
        self.name = name
        self.previewName = previewName
    }
    
    @objc func setDefault() {
        UserDefaults.standard.set(name, forKey: kCurrentBrushPrefKey)
    }
    
    let minStrokeWidth = CGFloat(kMinBrushSize)
    let maxStrokeWidth = CGFloat(kMaxBrushSize)    
    let defaultStrokeWidth = CGFloat(0.5 * kMaxBrushSize)
    
    @objc var strokeWidth: CGFloat {
        get {
            let maxWidths = UserDefaults.standard.dictionary(forKey: kMaximumLineWidthsPrefKey) as? [String: NSNumber]
            let maxWidth = CGFloat(maxWidths?[name]?.floatValue ?? Float(defaultStrokeWidth))
            return maxWidth
        }
        set {
            var maxWidths = UserDefaults.standard.dictionary(forKey: kMaximumLineWidthsPrefKey) as? [String: NSNumber]
            maxWidths?[name] = NSNumber(floatLiteral: Double(newValue))
            UserDefaults.standard.set(maxWidths, forKey: kMaximumLineWidthsPrefKey)
        }
    }
    
    @objc var strokeWidthFraction: CGFloat {
        get {
            return strokeWidth / maxStrokeWidth
        }
        set {
            let desiredValue = maxStrokeWidth * newValue
            let actualValue = min(max(minStrokeWidth, desiredValue), maxStrokeWidth)
            strokeWidth = actualValue
        }
    }
    
}

extension FBBrush {
    
    @objc static let allBrushes = [
        FBBrush(name: "Pencil", previewName: "pencilPreview"),
        FBBrush(name: "Ink", previewName: "inkPreview"),
        FBBrush(name: "Chalk", previewName: "chalkPreview")
    ]
    
    @objc static var currentBrush: FBBrush {
        return allBrushes.first(where: {
            return $0.name == UserDefaults.standard.string(forKey: kCurrentBrushPrefKey)
        }) ?? allBrushes[0]
    }
    
}
