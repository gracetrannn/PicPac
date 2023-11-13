//
//  ToolsToolbarView.swift
//  Toolbars
//
//  Created by Alex Vihlayew on 12/28/21.
//

import UIKit

@objc class FloatingView: UIView {
    
    var translation: CGPoint = .zero {
        didSet {
            refreshTransform()
        }
    }
    
    @objc enum Anchor: Int {
        case center
        case topLeading
        case topTrailing
        
        var correction: CGPoint {
            let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            switch self {
            case .center:
                return .zero
            case .topLeading:
                return CGPoint(x: !isRTL ? 0.5 : -0.5, y: 0.5)
            case .topTrailing:
                return CGPoint(x: !isRTL ? -0.5 : 0.5, y: 0.5)
            }
        }
    }
    
    @objc var anchor: Anchor = .center {
        didSet {
            self.correctPosition()
        }
    }
    
    @objc var position: CGPoint = .zero { // 0.0 - 1.0 for X, Y axis
        didSet {
            guard let superview = superview else { return }
            let targetOrigin = (position * superview.bounds.size) - (CGPoint(x: 0.5, y: 0.5) * frame.size)
            let originDelta = targetOrigin - self.frame.origin
            let anchorCorrection = anchor.correction * bounds.size
            self.translation = self.translation + originDelta + anchorCorrection
        }
    }
    
    @objc enum Orientation: Int {
        case horizontal
        case vertical
    }
    
    @objc var orientation: Orientation = .horizontal {
        didSet {
            refreshTransform()
        }
    }
    
    func refreshTransform() {
        transform = CGAffineTransform(translationX: translation.x, y: translation.y)
    }
    
    @objc func correctPosition() {
        let pos = self.position
        self.position = pos
    }
    
    @objc func correctPosition(for allowedRect: CGRect) {
        guard let superview = superview else {
            return
        }
        let superviewSize = superview.frame.size
        let halfSize = CGSize(
            width: 0.5 * frame.width,
            height: 0.5 * frame.height
        )
        var position = self.position
        if (frame.minX < allowedRect.minX) {
            position.x = (allowedRect.minX + halfSize.width) / superviewSize.width
        }
        if (frame.maxX > allowedRect.maxX) {
            position.x = (allowedRect.maxX - halfSize.width) / superviewSize.width
        }
        if (frame.minY < allowedRect.minY) {
            position.y = (allowedRect.minY + halfSize.height) / superviewSize.height
        }
        if (frame.maxY > allowedRect.maxY) {
            position.y = (allowedRect.maxY - halfSize.height) / superviewSize.height
        }
        self.position = position
    }
    
    func correctFrame() {
        
        if self.frame.origin.x < 0.0 {
            self.translation = self.translation + CGPoint(x: -self.frame.origin.x, y: 0.0)
        }
        if self.frame.origin.y < 0.0 {
            self.translation = self.translation + CGPoint(x: 0.0, y: -self.frame.origin.y)
        }
        
        guard let superview = superview,
              self.frame.origin.x + self.frame.size.width > superview.frame.width else {
            return
        }
        let deltaX = (self.frame.origin.x + self.frame.size.width) - superview.frame.width
        let deltaY = (self.frame.origin.y + self.frame.size.height) - superview.frame.height
        if deltaX > 0.0 {
            self.translation = self.translation + CGPoint(x: -deltaX, y: 0.0)
        }
        if deltaY > 0.0 {
            self.translation = self.translation + CGPoint(x: 0.0, y: -deltaY)
        }
    }
    
    // MARK: - Show / hide
    
    @objc func show() {
        UIView.animate(withDuration: 0.2) { [unowned self] in
            self.layer.opacity = 1.0
        }
    }
    
    @objc func hide() {
        UIView.animate(withDuration: 0.2) { [unowned self] in
            self.layer.opacity = 0.0
        }
    }
    
}
