//
//  FBShape.swift
//  FlipPad
//
//  Created by Akshay Phulare on 06/03/23.
//  Copyright © 2023 Alex. All rights reserved.
//

import Foundation

@objc class FBShape: NSObject {

    @objc let name: String
    @objc let previewName: String
    
    init(name: String, previewName: String) {
        self.name = name
        self.previewName = previewName
    }
    
    @objc func setDefault() {
        
        let previousSelection: String = UserDefaults.standard.string(forKey: kCurrentShapePrefKey) ?? ""
        if(previousSelection == name) {
            UserDefaults.standard.set("", forKey: kCurrentShapePrefKey)
        } else {
            UserDefaults.standard.set(name, forKey: kCurrentShapePrefKey)
        }
    }
    
}

extension FBShape {
    
    @objc static let allShapes = [
        FBShape(name: "Line", previewName: "line"),
        FBShape(name: "Circle", previewName: "circle"),
        FBShape(name: "Square", previewName: "square"),
        FBShape(name: "Multilines", previewName: "multilines")
    ]
    
    @objc static var currentShape: FBShape? {
        return allShapes.first(where: {
            return $0.name == UserDefaults.standard.string(forKey: kCurrentShapePrefKey)
        })
    }
    
}
