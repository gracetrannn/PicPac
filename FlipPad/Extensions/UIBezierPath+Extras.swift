//
//  UIBezierPath+Extras.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 3/5/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

extension CGPoint{
    
    func vector(to p1: CGPoint) -> CGVector{
        return CGVector(dx: p1.x-self.x, dy: p1.y-self.y)
    }
    
}

extension CGRect {
    
    var _center: CGPoint {
        return CGPoint(x: width / 2, y: height / 2)
    }
    
}

extension UIBezierPath {
    
    func moveCenter(to: CGPoint) -> Self {
        let bound  = self.cgPath.boundingBox
        let center = bounds._center
                
        let zeroedTo = CGPoint(x: to.x-bound.origin.x, y: to.y-bound.origin.y)
        let vector = center.vector(to: zeroedTo)

        return offset(to: CGSize(width: vector.dx, height: vector.dy))
    }
    
    func offset(to offset: CGSize) -> Self {
        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
        return applyCentered(transform: t)
    }
    
    func fit(into: CGRect) -> Self {
        let bounds = self.cgPath.boundingBox
        
        let factorX = into.size.width/bounds.width
        let factorY = into.size.height/bounds.height
                
        let scale = CGAffineTransform(scaleX: factorX, y: factorY)
        return applyCentered(transform: scale)
    }
    
    func applyCentered(transform: CGAffineTransform) -> Self {
        let bound  = self.cgPath.boundingBox
        let center = CGPoint(x: bound.midX, y: bound.midY)
        var xform  = CGAffineTransform.identity
        
        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        xform = xform.concatenating(transform)
        xform = xform.concatenating(CGAffineTransform(translationX: center.x, y: center.y))
        apply(xform)
        
        return self
    }
    
}
