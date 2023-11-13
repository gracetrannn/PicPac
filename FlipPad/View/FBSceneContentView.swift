//
//  FBSceneContentView.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 3/12/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

class FBSceneContentView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let pasteView = subviews.first(where: { $0 is FBPasteView }) {
            let translatedPoint: CGPoint = pasteView.convert(point, from: self)
            
            if pasteView.bounds.contains(translatedPoint) {
                return pasteView.hitTest(translatedPoint, with: event)
            }
            
            if pasteView.subviews.reduce(false, { (result, nextSubview) in
                return result || nextSubview.frame.contains(translatedPoint)
            }) {
                return pasteView.hitTest(translatedPoint, with: event)
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
}
