//
//  FBPasteView.swift
//  FlipPad
//
//  Created by Alex on 15.07.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit
import opencv2

@objc protocol FBPasteViewDelegate: AnyObject {
    
    func pasteRequested(pencilImage: FBImage?, fillImage: FBImage?, structureImage: FBImage?, transform: ImageTransform, shouldFinish: Bool)
            
    func cancelRequested()
    
}

@objc class FBPasteView: UIView {
    
    @objc weak var delegate: FBPasteViewDelegate?
    
    // Toggles
    @objc var togglesSize: CGFloat {
        return 48.0 / scale
    }
    
    private let pivotToggle = FBPasteToggleView()
    private let rotationToggle = FBPasteToggleView()
    //
    private let topToggle = FBPasteToggleView()
    private let bottomToggle = FBPasteToggleView()
    private let leftToggle = FBPasteToggleView()
    private let rightToggle = FBPasteToggleView()
    //
    private let topLeftToggle = FBPasteToggleView()
    private let topRightToggle = FBPasteToggleView()
    private let bottomLeftToggle = FBPasteToggleView()
    private let bottomRightToggle = FBPasteToggleView()
    
    // Toggle constraints
    private var topToggleTopAnchor: NSLayoutConstraint?
    private var bottomToggleBottomAnchor: NSLayoutConstraint?
    private var leftToggleLeftAnchor: NSLayoutConstraint?
    private var rightToggleRightAnchor: NSLayoutConstraint?
    
    private var topLeftToggleTopAnchor: NSLayoutConstraint?
    private var topLeftToggleLeftAnchor: NSLayoutConstraint?
    private var topRightToggleTopAnchor: NSLayoutConstraint?
    private var topRightToggleRightAnchor: NSLayoutConstraint?
    private var bottomLeftToggleLeftAnchor: NSLayoutConstraint?
    private var bottomLeftToggleBottomAnchor: NSLayoutConstraint?
    private var bottomRightToggleRightAnchor: NSLayoutConstraint?
    private var bottomRightToggleBottomAnchor: NSLayoutConstraint?
    
    private var toggleSizeConstraints = [NSLayoutConstraint]()
    
    // Line from rotation center to rotation toggle
    private let rotationAlignmentLayer = { () -> CALayer in
        let layer = CALayer()
        layer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        return layer
    }()
    
    // Mirror buttons
    
    private let cancelButton = { () -> UIButton in
        let button = UIButton()
        button.setTitle("X", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 36.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36.0).isActive = true
        return button
    }()
    private let mirrorHorizontalyButton = { () -> UIButton in
        let button = UIButton()
        button.setImage(UIImage(named: "flipH"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 36.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36.0).isActive = true
        return button
    }()
    private let mirrorVerticallyButton = { () -> UIButton in
        let button = UIButton()
        button.setImage(UIImage(named: "flipV"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 36.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36.0).isActive = true
        return button
    }()
    private let stampButton = { () -> UIButton in
        let button = UIButton()
        let color: UIColor = FeatureManager.shared.checkSubscribtion(.pro) ? .white : .gray
        
        if #available(iOS 13.0, *) {
            let image = UIImage(named: "stamp")?.withTintColor(color)
            button.setImage(image, for: .normal)
        } else {
            button.setImage(UIImage(named: "stamp"), for: .normal)
        }
        
        button.setTitleColor(.red, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.imageEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 36.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36.0).isActive = true
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
    
    // Images
    
    @objc var image: UIImage?
    
    @objc var pencilImage: FBImage?
    @objc var fillImage: FBImage?
    @objc var structureImage: FBImage?
    
    // Selection flashing
    
    var flashCount = 0
    var flashTimer: Timer?
    
    var scale: CGFloat {
        guard let transformingSceneView = superview?.superview as? FBTransformingSceneView else {
            return 1.0
        }
        return transformingSceneView.scale
    }
    
    private var initialFrame: CGRect = .zero
    var offset: CGPoint {
        return CGPoint(x: self.frame.origin.x - initialFrame.origin.x,
                       y: self.frame.origin.y - initialFrame.origin.y)
    }
    
    // Selection path
    
    @objc var path: UIBezierPath?
    @objc var isMoved: Bool = false
    
    // Transforms
    
    @objc var pivotPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    
    @objc var pivotTranslation: CGPoint = .zero
    @objc var moveTranslation: CGPoint = .zero
    
    @objc var translation: CGPoint {
        return pivotTranslation + moveTranslation
    }
    @objc var angle: CGFloat = 0.0
    
    @objc func configure() {
        isUserInteractionEnabled = true
        backgroundColor = .clear
//        layer.masksToBounds = false
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(move(recognizer:))))
        // Touch events
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch(recognizer:)))
        pinchRecognizer.delegate = self
        addGestureRecognizer(pinchRecognizer)
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate(recognizer:)))
        rotationRecognizer.delegate = self
        addGestureRecognizer(rotationRecognizer)
        
        self.configureToggles()
        self.configureMirrorIcons()
        
        flashTimer = Timer.scheduledTimer(timeInterval: TimeInterval(0.2), target: self, selector: #selector(flash), userInfo: nil, repeats: true)
        
        path = path?.fit(into: bounds).moveCenter(to: bounds.center)
        
        self.pivotTranslation = CGPoint(x: pivotPoint.x * bounds.width,
                                        y: pivotPoint.y * bounds.height)
        self.refreshTransform()
        
        setNeedsLayout()
        layoutIfNeeded()
        setNeedsDisplay()
        
        self.initialFrame = self.frame
    }
    
    private func configureToggles() {
        layer.addSublayer(rotationAlignmentLayer)
        
        addSubview(pivotToggle)
        addSubview(rotationToggle)
        
        addSubview(topToggle)
        addSubview(bottomToggle)
        addSubview(leftToggle)
        addSubview(rightToggle)
        
        addSubview(topLeftToggle)
        addSubview(topRightToggle)
        addSubview(bottomLeftToggle)
        addSubview(bottomRightToggle)
        
        // Pivot
        
        pivotToggle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(movePivot(recognizer:))))
        
        // Rotation
        
        rotationToggle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rotatePivot(recognizer:))))
        
        let offset: CGFloat = self.togglesSize / 2
        
        // Non-proportional
        
        topToggle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        topToggleTopAnchor = topToggle.topAnchor.constraint(equalTo: topAnchor, constant: -offset)
        
        bottomToggle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        bottomToggleBottomAnchor = bottomToggle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset)
        
        leftToggle.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        leftToggleLeftAnchor = leftToggle.leftAnchor.constraint(equalTo: leftAnchor, constant: -offset)
        
        rightToggle.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        rightToggleRightAnchor = rightToggle.rightAnchor.constraint(equalTo: rightAnchor, constant: offset)
        
        // Proportional
        
        topLeftToggleTopAnchor = topLeftToggle.topAnchor.constraint(equalTo: topAnchor, constant: -offset)
        topLeftToggleLeftAnchor = topLeftToggle.leftAnchor.constraint(equalTo: leftAnchor, constant: -offset)
        
        topRightToggleTopAnchor = topRightToggle.topAnchor.constraint(equalTo: topAnchor, constant: -offset)
        topRightToggleRightAnchor = topRightToggle.rightAnchor.constraint(equalTo: rightAnchor, constant: offset)
        
        bottomLeftToggleLeftAnchor = bottomLeftToggle.leftAnchor.constraint(equalTo: leftAnchor, constant: -offset)
        bottomLeftToggleBottomAnchor = bottomLeftToggle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset)
        
        bottomRightToggleRightAnchor = bottomRightToggle.rightAnchor.constraint(equalTo: rightAnchor, constant: offset)
        bottomRightToggleBottomAnchor = bottomRightToggle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset)
        
        
        for constraint in [topToggleTopAnchor,
                           leftToggleLeftAnchor,
                           topLeftToggleTopAnchor,
                           topLeftToggleLeftAnchor,
                           topRightToggleTopAnchor,
                           bottomLeftToggleLeftAnchor,
                           bottomToggleBottomAnchor,
                           rightToggleRightAnchor,
                           topRightToggleRightAnchor,
                           bottomLeftToggleBottomAnchor,
                           bottomRightToggleRightAnchor,
                           bottomRightToggleBottomAnchor] {
            constraint?.isActive = true
        }
        
        //
        
        for toggle in [topToggle, bottomToggle, leftToggle, rightToggle,
                       topLeftToggle, topRightToggle, bottomLeftToggle, bottomRightToggle] {
            let wAnchor = toggle.widthAnchor.constraint(equalToConstant: self.togglesSize)
            let hAnchor = toggle.heightAnchor.constraint(equalToConstant: self.togglesSize)
            wAnchor.isActive = true
            hAnchor.isActive = true
            toggleSizeConstraints.append(wAnchor)
            toggleSizeConstraints.append(hAnchor)
        }
        
        for toggle in [topToggle, bottomToggle, leftToggle, rightToggle] {
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(scale(_:)))
            toggle.addGestureRecognizer(recognizer)
        }
        
        for toggle in [topLeftToggle, topRightToggle, bottomLeftToggle, bottomRightToggle] {
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(scaleProportionally(_:)))
            toggle.addGestureRecognizer(recognizer)
        }
    }
    
    private func configureMirrorIcons() {
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        mirrorVerticallyButton.addTarget(self, action: #selector(mirrorVertically), for: .touchUpInside)
        mirrorHorizontalyButton.addTarget(self, action: #selector(mirrorHorizontaly), for: .touchUpInside)
        stampButton.addTarget(self, action: #selector(stamp), for: .touchUpInside)
        
        buttonsStackView.addArrangedSubview(cancelButton)
        buttonsStackView.addArrangedSubview(mirrorVerticallyButton)
        buttonsStackView.addArrangedSubview(mirrorHorizontalyButton)
        buttonsStackView.addArrangedSubview(stampButton)
        
        addSubview(buttonsStackView)
    }
    
    @objc func cancel() {
        SettingsBundleHelper.editModeDevice = false
        delegate?.cancelRequested()
    }
    
    @objc func mirrorVertically() {
        image = image?.flippedVertically()
        pencilImage = pencilImage?.flippedVertically()
        structureImage = structureImage?.flippedVertically()
        fillImage = fillImage?.flippedVertically()
        
        setNeedsDisplay()
    }
    
    @objc func mirrorHorizontaly() {
        image = image?.flippedHorizontally()
        pencilImage = pencilImage?.flippedHorizontally()
        structureImage = structureImage?.flippedHorizontally()
        fillImage = fillImage?.flippedHorizontally()
        
        setNeedsDisplay()
    }
    
    @objc func stamp() {
        guard FeatureManager.shared.checkSubscribtion(.pro) else {
            let vc = self.delegate as? UIViewController ?? UIViewController()
            UIAlertController.showBlockedAlertController(for: vc, feature: "Stamp", level: "Pro")
            return
        }
        delegate?.pasteRequested(pencilImage: pencilImage,
                                 fillImage: fillImage,
                                 structureImage: structureImage,
                                 transform: self.imageTransform(), shouldFinish: false)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in [topToggle, bottomToggle, leftToggle, rightToggle,
                       topLeftToggle, topRightToggle, bottomLeftToggle, bottomRightToggle,
                       pivotToggle, rotationToggle,
                       cancelButton, mirrorHorizontalyButton, mirrorVerticallyButton, stampButton] {
            let translatedPoint: CGPoint = view.convert(point, from: self)
            
            if view.bounds.contains(translatedPoint) {
                return view
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Rotation center
        
        let pivotCenterPoint = CGPoint(x: (pivotPoint.x * bounds.width), y: (pivotPoint.y * bounds.height))
        pivotToggle.frame = CGRect(origin: pivotCenterPoint.offsetedBy(x: self.togglesSize / -2, y: self.togglesSize / -2),
                                   size: CGSize(width: self.togglesSize, height: self.togglesSize))
        
        // Rotation toggle
        
        let rotationPoint = bounds.center + CGPoint(x: 0.0, y: (bounds.height / 2) + (40.0 / scale))
        rotationToggle.frame = CGRect(origin: rotationPoint.offsetedBy(x: self.togglesSize / -2, y: self.togglesSize / -2),
                                      size: CGSize(width: self.togglesSize, height: self.togglesSize))
        
        // Other toggles
        
        for constraint in toggleSizeConstraints {
            constraint.constant = self.togglesSize
        }
        let offset: CGFloat = self.togglesSize / 2
        for constraint in [topToggleTopAnchor,
                           leftToggleLeftAnchor,
                           topLeftToggleTopAnchor,
                           topLeftToggleLeftAnchor,
                           topRightToggleTopAnchor,
                           bottomLeftToggleLeftAnchor] {
            constraint?.constant = -offset
        }
        for constraint in [bottomToggleBottomAnchor,
                           rightToggleRightAnchor,
                           topRightToggleRightAnchor,
                           bottomLeftToggleBottomAnchor,
                           bottomRightToggleRightAnchor,
                           bottomRightToggleBottomAnchor] {
            constraint?.constant = offset
        }
        
        // Line from rotation center to rotation toggle
        
        let lineLength = rotationPoint.distance(to: pivotCenterPoint)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rotationAlignmentLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        rotationAlignmentLayer.frame = CGRect(origin: pivotCenterPoint, size: CGSize(width: lineLength, height: 1.0))
        rotationAlignmentLayer.bounds = CGRect(origin: .zero, size: CGSize(width: lineLength, height: 1.0))
        let referencePoint = pivotCenterPoint + CGPoint(x: 0.0, y: -10.0)
        let angle: CGFloat = atan2(rotationPoint.y - pivotCenterPoint.y,
                                   rotationPoint.x - pivotCenterPoint.x)
                            - atan2(referencePoint.y - pivotCenterPoint.y,
                                    referencePoint.x - pivotCenterPoint.x)
        let transform = CGAffineTransform.identity
            .rotated(by: angle - (.pi / 2))
        rotationAlignmentLayer.setAffineTransform(transform)
        CATransaction.commit()
        
        self.updateMirrorButtonsLocation(animated: false)
    }
    
    private func updateMirrorButtonsLocation(animated: Bool) {
        // Mirror buttons
        
        var directionX: CGFloat = -1.0
        var directionY: CGFloat = -1.0
        
        if frame.origin.x < 0.0 {
            directionX = 1.0
        }
        if frame.origin.y < 0.0 {
            directionY = 1.0
        }
        
        let newTransform = CGAffineTransform.identity
            .translatedBy(x: adjustedSize.width / 2, y: adjustedSize.height / 2)
            .translatedBy(x: -buttonsStackView.bounds.width / 2, y: -buttonsStackView.bounds.height / 2)
            .rotated(by: -self.angle)
            .translatedBy(x: ((adjustedSize.width / 2) + (buttonsStackView.bounds.width / scale / 2) + 8) * directionX,
                          y: ((adjustedSize.height / 2) + (buttonsStackView.bounds.height / scale / 2) + 8) * directionY)
            .scaledBy(x: 1.0 / scale, y: 1.0 / scale)
        
        if animated {
            UIView.animate(withDuration: 0.1) {
                self.buttonsStackView.transform = newTransform
            }
        } else {
            self.buttonsStackView.transform = newTransform
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let correctedPath: UIBezierPath? = path?.copy() as! UIBezierPath?

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        context?.clear(rect)
        
        image?.draw(in: rect)
        
        // Selection
        
        correctedPath?.lineWidth = 2.0 / scale
        correctedPath?.lineJoinStyle = .round
        
        let section = 6.0 / scale
        let pattern: [CGFloat] = [section, section]
        
        UIColor.black.setStroke()
        correctedPath?.setLineDash(pattern, count: 2, phase: CGFloat(flashCount) / scale * 2)
        correctedPath?.stroke()
        
        UIColor.white.setStroke()
        correctedPath?.setLineDash(pattern, count: 2, phase: CGFloat(flashCount) / scale * 2 + section)
        correctedPath?.stroke()
        
        let border = UIBezierPath(rect: bounds)
        border.lineWidth = 2.0 / scale
        UIColor.systemBlue.withAlphaComponent(0.3).setStroke()
        border.stroke()
        
        // Lines
        
        context?.strokeLineSegments(between: [CGPoint.zero, pivotToggle.center])
        context?.strokeLineSegments(between: [CGPoint(x: 0.0, y: bounds.height), pivotToggle.center])
        context?.strokeLineSegments(between: [CGPoint(x: bounds.width, y: 0.0), pivotToggle.center])
        context?.strokeLineSegments(between: [CGPoint(x: bounds.width, y: bounds.height), pivotToggle.center])
        
        context?.restoreGState()
    }
    
    @objc private func flash() {
        flashCount += 1
        setNeedsDisplay()
    }
    
    // MARK: - Paste
    
    private func imageTransform() -> ImageTransform {
        let imageSize = (self.pencilImage?.size ?? self.structureImage?.size ?? self.fillImage?.size) ?? .zero
        
        // Source
        let x1: Float = Float(self.initialFrame.minX)
        let y1: Float = Float(imageSize.height - self.initialFrame.maxY)
        ///
        let x2: Float = Float(self.initialFrame.minX)
        let y2: Float = Float(imageSize.height - self.initialFrame.minY)
        ///
        let x3: Float = Float(self.initialFrame.maxX)
        let y3: Float = Float(imageSize.height - self.initialFrame.minY)
        
        
        let bottomLeft = superview!.convert(self.bottomLeftToggle.bounds.center, from: self.bottomLeftToggle)
        let topLeft = superview!.convert(self.topLeftToggle.bounds.center, from: self.topLeftToggle)
        let topRight = superview!.convert(self.topRightToggle.bounds.center, from: self.topRightToggle)
        
        // Result
        let x1p: Float = Float(bottomLeft.x)
        let y1p: Float = Float(imageSize.height - bottomLeft.y)
        ///
        let x2p: Float = Float(topLeft.x)
        let y2p: Float = Float(imageSize.height - topLeft.y)
        ///
        let x3p: Float = Float(topRight.x)
        let y3p: Float = Float(imageSize.height - topRight.y)
        
        let sourcePoints = simd_float3x3(SIMD3<Float>(x1, x2, x3),
                                         SIMD3<Float>(y1, y2, y3),
                                         SIMD3<Float>(1, 1, 1)).transpose
        
        let resultPoints = simd_float3x3(SIMD3<Float>(x1p, x2p, x3p),
                                         SIMD3<Float>(y1p, y2p, y3p),
                                         SIMD3<Float>(1, 1, 1)).transpose
                        
        let transform = simd_mul(resultPoints, sourcePoints.inverse)

        let height = Float(superview!.bounds.height)
        
        return ImageTransform(src: [
            Point2f(x: x1, y: height - y1),
            Point2f(x: x2, y: height - y2),
            Point2f(x: x3, y: height - y3),
        ], dst: [
            Point2f(x: x1p, y: height - y1p),
            Point2f(x: x2p, y: height - y2p),
            Point2f(x: x3p, y: height - y3p),
        ])
        
//        return CGAffineTransform(a: CGFloat(transform.columns.0.x), b: CGFloat(transform.columns.0.y),
//                                 c: CGFloat(transform.columns.1.x), d: CGFloat(transform.columns.1.y),
//                                 tx: CGFloat(transform.columns.2.x), ty: CGFloat(transform.columns.2.y))
    }
    
    @objc func paste() {
        delegate?.pasteRequested(pencilImage: pencilImage,
                                 fillImage: fillImage,
                                 structureImage: structureImage,
                                 transform: self.imageTransform(), shouldFinish: true)
        removeFromSuperview()
    }
    
    // MARK: - Scaling
    
    @objc func scale(_ recognizer: UIPanGestureRecognizer) {
        
        guard FeatureManager.shared.checkSubscribtion(.studio) else {
            let delegate = self.delegate as? UIViewController ?? UIViewController()
            UIAlertController.showBlockedAlertController(for: delegate, feature: "Squash and Stretch", level: "Studio or higher")
            return
        }
        
        let translation = recognizer.translation(in: self)
        recognizer.setTranslation(.zero, in: self)
        
        if recognizer.view == topToggle {
            self.bounds = self.bounds.insetBy(dx: 0.0, dy: translation.y)
        }
        if recognizer.view == bottomToggle {
            self.bounds = self.bounds.insetBy(dx: 0.0, dy: -translation.y)
        }
        if recognizer.view == leftToggle {
            self.bounds = self.bounds.insetBy(dx: translation.x, dy: 0.0)
        }
        if recognizer.view == rightToggle {
            self.bounds = self.bounds.insetBy(dx: -translation.x, dy: 0.0)
        }
        self.bounds.origin = .zero
             
        isMoved = true
        path = path?.fit(into: bounds).moveCenter(to: bounds.center)
                
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    @objc func scaleProportionally(_ recognizer: UIPanGestureRecognizer) {
        
        guard FeatureManager.shared.checkSubscribtion(.lite) else {
            let delegate = self.delegate as? UIViewController ?? UIViewController()
            UIAlertController.showBlockedAlertController(for: delegate, feature: "Scale", level: "Lite or higher")
            return
        }
        
        var translation = recognizer.translation(in: self)
        recognizer.setTranslation(.zero, in: self)
        
        // Correct translation direction
        if recognizer.view == topLeftToggle {
            // Good
        }
        if recognizer.view == topRightToggle {
            translation.x = -translation.x
        }
        if recognizer.view == bottomLeftToggle {
            translation.y = -translation.y
        }
        if recognizer.view == bottomRightToggle {
            translation.y = -translation.y
            translation.x = -translation.x
        }
        
        let scaleX = self.bounds.width / ((translation.x * 2) + self.bounds.width)
        let scaleY = self.bounds.height / ((translation.y * 2) + self.bounds.height)
        var avgScale = (scaleX + scaleY) / 2
        
        if ((self.bounds.width < 50.0) || (self.bounds.height < 50.0)) && avgScale < 1.0 {
            avgScale = 1.0
        }
        
        self.bounds = CGRect(origin: .zero, size: CGSize(width: self.bounds.width * avgScale,
                                                         height: self.bounds.height * avgScale))
        
        isMoved = true
        path = path?.fit(into: bounds).moveCenter(to: bounds.center)
                
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    @objc func pinch(recognizer: UIPinchGestureRecognizer) {
        let scale = recognizer.scale
        recognizer.scale = 1.0
        //
        self.bounds = CGRect(origin: .zero, size: CGSize(width: self.bounds.width * scale,
                                                         height: self.bounds.height * scale))
        
        isMoved = true
        path = path?.fit(into: bounds).moveCenter(to: bounds.center)
                
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    // MARK: - Pivot point
    
    @objc func movePivot(recognizer: UIPanGestureRecognizer) {
        guard let pivotView = recognizer.view else {
            return
        }
        
        let translation = recognizer.translation(in: self)
        recognizer.setTranslation(.zero, in: self)
        
        // Update pivot frame
        let newPivotFrame = pivotView.frame.offsetBy(dx: translation.x, dy: translation.y)
        pivotView.frame = self.correctedNestedFrame(rect: newPivotFrame)
        
        // Update pivot point
        self.pivotPoint = CGPoint(x: pivotView.frame.center.x / bounds.width,
                                  y: pivotView.frame.center.y / bounds.height)
        
        // Correct translation to stay at same place
        self.pivotTranslation += translation.applying(CGAffineTransform(rotationAngle: self.angle))
        
        self.refreshTransform()
        
        setNeedsDisplay()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK: - Rotate
    
    private var panStartPoint: CGPoint = .zero
    
    @objc func rotatePivot(recognizer: UIPanGestureRecognizer) {
        
        guard FeatureManager.shared.checkSubscribtion(.lite) else {
            let delegate = self.delegate as? UIViewController ?? UIViewController()
            UIAlertController.showBlockedAlertController(for: delegate, feature: "Rotate", level: "Lite or higher")
            return
        }
        
        if recognizer.state == .began {
            panStartPoint = recognizer.location(in: self)
        }
        
        recognizer.setTranslation(.zero, in: self)
        
        let pivotX = self.bounds.width * pivotPoint.x
        let pivotY = self.bounds.height * pivotPoint.y
        
        let rotationCenter = CGPoint(x: pivotX, y: pivotY)
        let location = recognizer.location(in: self)
        
        let angle: CGFloat = atan2(location.y - rotationCenter.y,
                                   location.x - rotationCenter.x)
                            - atan2(panStartPoint.y - rotationCenter.y,
                                    panStartPoint.x - rotationCenter.x)
        self.angle += angle
        isMoved = true
        
        self.refreshTransform()
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc func rotate(recognizer: UIRotationGestureRecognizer) {
        
        guard FeatureManager.shared.checkSubscribtion(.lite) else {
            let delegate = self.delegate as? UIViewController ?? UIViewController()
            UIAlertController.showBlockedAlertController(for: delegate, feature: "Rotate", level: "Lite or higher")
            return
        }
        
        let rotation = recognizer.rotation
        recognizer.rotation = 0.0
        //
        self.angle += rotation
        isMoved = true
        
        self.refreshTransform()
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK: - Movement
    
    @objc func move(recognizer: UIPanGestureRecognizer) {
        guard let superview = superview else {
            return
        }
        
        let offset = recognizer.translation(in: superview)
        
        switch recognizer.state {
        case .changed:
            self.moveTranslation += offset
            isMoved = true

            UIView.animate(withDuration: 0.1) {
                self.refreshTransform()
            }
            self.updateMirrorButtonsLocation(animated: true)
        default:
            break
        }
        
        recognizer.setTranslation(.zero, in: superview)
    }
    
    //
    
    private func refreshTransform() {
        self.layer.anchorPoint = pivotPoint
        
        self.transform = CGAffineTransform.identity
            .translatedBy(x: translation.x, y: translation.y) // Movement
            .rotated(by: angle) // Rotation
    }
    
}

extension FBPasteView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (otherGestureRecognizer.view == self) {
            return true
        }
        return false
    }
    
}

extension CGAffineTransform {
    
    var angle: CGFloat { return atan2(-self.c, self.a) }

    var angleInDegrees: CGFloat { return self.angle * 180 / .pi }

    var scaleX: CGFloat {
        let angle = self.angle
        return self.a * cos(angle) - self.c * sin(angle)
    }

    var scaleY: CGFloat {
        let angle = self.angle
        return self.d * cos(angle) + self.b * sin(angle)
    }
    
}

extension UIView {
    
    var adjustedSize: CGSize {
        let scaleX = self.transform.scaleX
        let scaleY = self.transform.scaleY
        return CGSize(width: self.bounds.size.width * scaleX,
                      height: self.bounds.size.height * scaleY)
    }
    
    func correctedNestedFrame(rect: CGRect) -> CGRect {
        let xOffset = (rect.size.width * 0.9)
        let yOffset = (rect.size.height * 0.9)
        
        let MIN_X: CGFloat = 0.0 - xOffset
        let MIN_Y: CGFloat = 0.0 - yOffset
        
        let MAX_X: CGFloat = self.bounds.width - rect.size.width + xOffset
        let MAX_Y: CGFloat = self.bounds.height - rect.size.height + yOffset
        
        let X = min(max(MIN_X, rect.origin.x), MAX_X)
        let Y = min(max(MIN_Y, rect.origin.y), MAX_Y)
        
        return CGRect(origin: CGPoint(x: X, y: Y), size: rect.size)
    }
    
    public func offTamic() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
