//
//  FloatingToolbarView.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/2/22.
//  Copyright © 2022 Alex. All rights reserved.
//

import UIKit
import Foundation

@objc class FloatingToolbarView: FloatingView {
    
    // MARK: - Subviews
    
    private let effectView = { () -> UIView in
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12.0
        view.layer.masksToBounds = true
        return view
    }()
    
    private var shadowLayer: CAShapeLayer?
    
    //
    
    func configure(_ length: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        
        widthAnchor.constraint(equalToConstant: length).isActive = true
        
        addSubview(effectView)
        topAnchor.constraint(equalTo: effectView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: effectView.bottomAnchor).isActive = true
        leftAnchor.constraint(equalTo: effectView.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: effectView.rightAnchor).isActive = true
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragged(_:))))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.shadowLayer == nil {
            let shadowLayer = CAShapeLayer()
            shadowLayer.fillColor = UIColor.clear.cgColor
            shadowLayer.shadowColor = UIColor.black.cgColor
            layer.insertSublayer(shadowLayer, at: 0)
            self.shadowLayer = shadowLayer
        }
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 12.0).cgPath
        shadowLayer?.path = path
        shadowLayer?.shadowPath = path
        shadowLayer?.shadowOffset = CGSize(width: 0.0, height: 2.0)
        shadowLayer?.shadowOpacity = 0.15
        shadowLayer?.shadowRadius = 2.0
    }
    
    // MARK: - UIPanGestureRecognizer
    
    @objc func dragged(_ recognizer: UIPanGestureRecognizer) {
        let delta = recognizer.translation(in: self).applying(orientation == .vertical ? .init(rotationAngle: .pi / 2.0) : .identity)
        recognizer.setTranslation(.zero, in: self)
        let newTranslation = CGPoint(x: self.translation.x + delta.x,
                                     y: self.translation.y + delta.y)
        self.translation = newTranslation
        self.correctFrame()
        
        // Update relative position
        let anchorCorrection = anchor.correction * bounds.size
        self.position = (superview!.convert(bounds.center, from: self) - anchorCorrection) / superview!.bounds.size
        switch recognizer.state {
        case .ended, .cancelled:
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kToolBarPositionChanged), object: nil)
        default :
            break
        }
    }
    
}
