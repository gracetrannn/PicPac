//
//  FBLassoView.swift
//  FlipPad
//
//  Created by Alex on 15.07.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit

@objc protocol FBLassoViewDelegate: class {

    func willStartSelecting()
    
    func cutRequested(path: UIBezierPath, fromPoint: CGPoint)
    
    func copyRequested(path: UIBezierPath, fromPoint: CGPoint)
    
}

@objc class FBLassoView: UIView {
    
    @objc weak var delegate: FBLassoViewDelegate?
    
    private let cutButton = { () -> UIButton in
        let button = UIButton()
        button.setImage(UIImage(named: "cut"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        return button
    }()
    private let copyButton = { () -> UIButton in
        let button = UIButton()
        button.setImage(UIImage(named: "copy"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        return button
    }()
    private let buttonsStackView = { () -> UIStackView in
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    var path: UIBezierPath?
    var points = [CGPoint]()
    
    var flashCount = 0
    var flashTimer: Timer?
    var scale: CGFloat {
        guard let transformingSceneView = superview?.superview as? FBTransformingSceneView else {
            return 1.0
        }
        return transformingSceneView.scale
    }
    
    override var canBecomeFirstResponder: Bool { return true }
    
    @objc func configure() {
        backgroundColor = .clear
                
        flashTimer = Timer.scheduledTimer(timeInterval: TimeInterval(0.2), target: self, selector: #selector(flash), userInfo: nil, repeats: true)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context?.clear(rect)
        
        path?.lineWidth = 2.0 / scale
        path?.lineJoinStyle = .round
        
        let section = 6.0 / scale
        let pattern: [CGFloat] = [section, section]
        
        UIColor.black.setStroke()
        path?.setLineDash(pattern, count: 2, phase: CGFloat(flashCount) / scale * 2)
        path?.stroke()
        
        UIColor.white.setStroke()
        path?.setLineDash(pattern, count: 2, phase: CGFloat(flashCount) / scale * 2 + section)
        path?.stroke()
    }
    
    @objc private func flash() {
        flashCount += 1
        setNeedsDisplay()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.hideOptions()
        
        guard let location = touches.first?.location(in: self) else {
            return
        }
        
        delegate?.willStartSelecting()
        
        path = UIBezierPath()
        points = []
        
        path?.move(to: location)
        points.append(location)
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let location = touches.first?.location(in: self) {
            let adjustedLocation = adjustedPathPointLocation(from: location)
            path?.addLine(to: adjustedLocation)
            points.append(adjustedLocation)
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        path?.close()
        setNeedsDisplay()
        
        guard path != nil, points.count > 5 else { return }
        
        self.showOptions()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        path = nil
        points = []
        setNeedsDisplay()
    }
    
    private func showOptions() {
        cutButton.addTarget(self, action: #selector(cutSelection), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copySelection), for: .touchUpInside)
        
        buttonsStackView.addArrangedSubview(cutButton)
        buttonsStackView.addArrangedSubview(copyButton)
        
        addSubview(buttonsStackView)
        
        guard let minX = points.sorted(by: { $0.x < $1.x }).first?.x,
              let maxX = points.sorted(by: { $0.x < $1.x }).last?.x,
              let minY = points.sorted(by: { $0.y < $1.y }).first?.y else { return }
        
        layoutIfNeeded()
        
        buttonsStackView.center = CGPoint(x: (minX + maxX) / 2, y: minY)
        buttonsStackView.transform = CGAffineTransform.identity.scaledBy(x: 1.0 / scale, y: 1.0 / scale)
    }
    
    private func hideOptions() {
        buttonsStackView.removeFromSuperview()
    }
    
    @objc func cutSelection() {
        if let path = path, points.count > 5 {
            let minX = points.map({ $0.x }).sorted().first ?? 0.0
            let minY = points.map({ $0.y }).sorted().first ?? 0.0
            
            delegate?.cutRequested(path: path, fromPoint: CGPoint(x: minX, y: minY))
        }
        
        path = nil
        points = []
        
        self.hideOptions()
    }

    @objc func copySelection() {
        if let path = path, points.count > 5 {
            let minX = points.map({ $0.x }).sorted().first ?? 0.0
            let minY = points.map({ $0.y }).sorted().first ?? 0.0
            
            delegate?.copyRequested(path: path, fromPoint: CGPoint(x: minX, y: minY))
        }
        
        path = nil
        points = []
        
        self.hideOptions()
    }
    
    func adjustedPathPointLocation(from point: CGPoint) -> CGPoint {
        let x = min(max(0, point.x), bounds.size.width)
        let y = min(max(0, point.y), bounds.size.height)
        return CGPoint(x: x, y: y)
    }
    
}
