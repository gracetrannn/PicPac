//
//  FBPasteToggleView.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 3/16/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

class FBPasteToggleView: UIView {
    
    static let size = CGSize(width: 8.0, height: 8.0)
    var scale: CGFloat {
        if let view = superview as? FBPasteView {
            return view.scale
        } else {
            return 1.0
        }
    }
    
    enum Kind {
        case square
        case circle
    }
    
    var kind: Kind = .circle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    
        configure()
    }
    
    private func configure() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()!
        
        let toggleSize = CGSize(width: FBPasteToggleView.size.width / scale, height: FBPasteToggleView.size.height / scale)
        
        let pathRect = CGRect(origin: CGPoint(x: (frame.width - toggleSize.width) / 2.0,
                                              y: (frame.height - toggleSize.height) / 2.0),
                              size: toggleSize)
                
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        
        context.setLineWidth(2.0 / scale)
        
        switch kind {
        case .square:
            context.addRect(pathRect)
        case .circle:
            context.addEllipse(in: pathRect)
        }
        
        context.drawPath(using: CGPathDrawingMode.eoFillStroke)
    }
    
}
