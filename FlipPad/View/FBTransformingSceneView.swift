//
// FBTransformingSceneView.swift
//

import UIKit

@objc protocol FBTransformingSceneViewDelegate: AnyObject {
    
    func transformingSceneView(_ transformingSceneView: FBTransformingSceneView)
}

@objc class FBTransformingSceneView: UIView {
    
    // MARK: -
    
    @objc public enum Mode: Int {
        
        case undefined = 0
        case moving
        case rotating
        case scaling
    }
    
    // MARK: -
    
    private enum AspectMode {
        
        case fill
        case fit
    }
    
    // MARK: -
    
    @objc weak var delegate: FBTransformingSceneViewDelegate?
    
    @objc var sourceView = UIView() {
        didSet {
            originSourceViewFrame = sourceView.frame
            let view: UIView
#if targetEnvironment(macCatalyst)
            view = dragView
#else
            view = self
#endif
            view.insertSubview(sourceView, at: 0)
            addConstraints(
                [
                    .init(
                        item: view,
                        attribute: .centerX,
                        relatedBy: .equal,
                        toItem: sourceView,
                        attribute: .centerX,
                        multiplier: 1.0,
                        constant: 0.0
                    ),
                    .init(
                        item: view,
                        attribute: .centerY,
                        relatedBy: .equal,
                        toItem: sourceView,
                        attribute: .centerY,
                        multiplier: 1.0,
                        constant: 0.0
                    )
                ]
            )
        }
    }
    
    @objc var mode = Mode.undefined {
        didSet {
#if targetEnvironment(macCatalyst)
            let isEnabled = mode != .undefined
            longPressGestureRecognizer?.isEnabled = isEnabled
            hoverGestureRecognizer?.isEnabled = isEnabled
#endif
        }
    }
    
    @objc var scale: CGFloat {
        return sourceView.transform.scaleX
    }
    
    @objc var angle: CGFloat {
        return sourceView.transform.angle
    }
    
    @objc var delta: CGPoint {
        let transform = sourceView.transform
        return CGPoint(
            x: transform.tx,
            y: transform.ty
        )
    }
    
    @objc var maxScale: CGFloat = 16.0
    @objc var minScale: CGFloat = 0.02
    
    // MARK: -
    
    private var originA: CGPoint?
    private var originB: CGPoint?
    
    private var currentA: CGPoint?
    private var currentB: CGPoint?
    
    private var originTransform = CGAffineTransform.identity
    
    private var originSourceViewFrame = CGRect.zero
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
#if targetEnvironment(macCatalyst)
    
    private var dragView = UIView()
    
    private var _center: CGPoint?
    
    private var originLine = Line(a: .zero, b: .zero)
    private var currentLine = Line(a: .zero, b: .zero)
    
    private var dragOriginTransform = CGAffineTransform.identity
    
    private var hoverGestureRecognizer: UIHoverGestureRecognizer!
    
    private var anchor: CGPoint {
        return _center ?? center
    }
    
#endif
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: -
    
    override func layoutSubviews() {
        super.layoutSubviews()
#if targetEnvironment(macCatalyst)
        _center = center + CGPoint(
            x: dragView.transform.tx,
            y: dragView.transform.ty
        )
#endif
    }
    
    // MARK: -
    
    @objc func zoomToFill(_ animated: Bool = true) {
        zoom(to: .fill, animated: animated)
    }
    
    @objc func zoomToFit(_ animated: Bool = true) {
        zoom(to: .fit, animated: animated)
    }
    
    @objc func zoomToScale(_ scale: CGFloat, animated: Bool = true) {
        let transform = CGAffineTransform(
            scaleX: scale,
            y: scale
        )
            .rotated(
                by: sourceView.transform.angle
            )
        if animated {
            UIView.animate(withDuration: 0.24) {
                self.sourceView.transform = transform
            } completion: { _ in
                self.send()
            }
        } else {
            sourceView.transform = transform
            send()
        }
    }
    
    @objc func applyTransform(_ transform: CGAffineTransform, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.24) {
                self._applyTransform(transform)
            }
        } else {
            _applyTransform(transform)
        }
    }
    
    private func _applyTransform(_ transform: CGAffineTransform) {
#if targetEnvironment(macCatalyst)
        dragView.transform = CGAffineTransform(
            a: 1.0,
            b: 0.0,
            c: 0.0,
            d: 1.0,
            tx: transform.tx,
            ty: transform.ty
        )
        sourceView.transform = CGAffineTransform(
            a: transform.a,
            b: transform.b,
            c: transform.c,
            d: transform.d,
            tx: 0.0,
            ty: 0.0
        )
        
#else
        sourceView.transform = transform
#endif
    }
    
    @objc func getTransform() -> CGAffineTransform {
#if targetEnvironment(macCatalyst)
        let source = sourceView.transform
        let drag = dragView.transform
        return CGAffineTransform(a: source.a, b: source.b, c: source.c, d: source.d, tx: drag.tx, ty: drag.ty)
#else
        return sourceView.transform
#endif
    }
    
    @objc func resetTransform(_ animated: Bool = true) {
        originTransform = sourceView.transform
#if targetEnvironment(macCatalyst)
        dragOriginTransform = dragView.transform
#endif
        zoom(to: .fit, animated: animated)
    }
    
    @objc func restoreTransform(_ animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.24) {
                self.sourceView.transform = self.transform
            } completion: { _ in
                self.send()
            }
        } else {
            sourceView.transform = originTransform
#if targetEnvironment(macCatalyst)
            dragView.transform = dragOriginTransform
#endif
            send()
        }
    }
    
    // MARK: -
    
    private func setup() {
#if targetEnvironment(macCatalyst)
        let numberOfTouchesRequired = 1
#else
        let numberOfTouchesRequired = 2
#endif
        longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longPressGestureRecognizerHandler(_:))
        )
        longPressGestureRecognizer.minimumPressDuration = 0.0
        longPressGestureRecognizer.numberOfTouchesRequired = numberOfTouchesRequired
        addGestureRecognizer(longPressGestureRecognizer)
#if targetEnvironment(macCatalyst)
        dragView.clipsToBounds = false
        dragView.backgroundColor = .clear
        addSubview(dragView)
        dragView.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .right, .bottom, .left]
        let constraints = attributes.map {
            NSLayoutConstraint(
                item: self,
                attribute: $0,
                relatedBy: .equal,
                toItem: dragView,
                attribute: $0,
                multiplier: 1.0,
                constant: 0.0
            )
        }
        addConstraints(constraints)
        hoverGestureRecognizer = UIHoverGestureRecognizer(
            target: self,
            action: #selector(hoverGestureRecognizeHandler(_:))
        )
        addGestureRecognizer(hoverGestureRecognizer)
#if DEBUG
        let subview = subviews.first { $0 is StylusSettingsView }
        if let subview = subview {
            bringSubviewToFront(subview)
        }
#endif
#endif
        mode = .undefined
    }
    
    private func calculate() {
#if targetEnvironment(macCatalyst)
        guard
            let originA = originA,
            let currentA = currentA
        else {
            return
        }
        switch self.mode {
        case .undefined:
            break
        case .moving:
            let delta = originA - currentA
            let transform = CGAffineTransform(translationX: -delta.x, y: -delta.y)
            dragView.transform = dragOriginTransform.concatenating(transform)
            _center = center + CGPoint(
                x: dragView.transform.tx,
                y: dragView.transform.ty
            )
        case .scaling:
            
            let center = CGPoint(
                x: 0.5 * bounds.width,
                y: 0.5 * bounds.height
            )
            let originLength = Line(a: center, b: originA).vector.length
            let currentLength = Line(a: center, b: currentA).vector.length
            var scale = currentLength / originLength
            
            if scale < minScale {
                scale = minScale
            }
            if scale > maxScale {
                scale = maxScale
            }
            let transform = CGAffineTransform(
                scaleX: scale,
                y: scale
            )
            sourceView.transform = originTransform.concatenating(transform)
        case .rotating:
            let angle = originLine.angle(to: currentLine)
            let transform = CGAffineTransform(rotationAngle: -angle)
            sourceView.transform = originTransform.concatenating(transform)
        }
#else
        guard
            let originA = originA,
            let originB = originB,
            let currentA = currentA,
            let currentB = currentB
        else {
            return
        }
        let originDistance = originA.distance(to: originB)
        let currentDistance = currentA.distance(to: currentB)
        let originLine = Line(a: originA, b: originB)
        let currentLine = Line(a: currentA, b: currentB)
        let offset = center - currentLine.center
        var scale = currentDistance / originDistance
        let angle = originLine.angle(to: currentLine)
        let delta = originLine.center - currentLine.center
        if scale < minScale {
            scale = minScale
        }
        if scale > maxScale {
            scale = maxScale
        }
        let transform = CGAffineTransform.identity
            .translatedBy(
                x: -offset.x,
                y: -offset.y
            )
            .scaledBy(
                x: scale,
                y: scale
            )
            .rotated(
                by: -angle
            )
            .translatedBy(
                x: -delta.x,
                y: -delta.y
            )
            .translatedBy(
                x: offset.x,
                y: offset.y
            )
        sourceView.transform = originTransform.concatenating(transform)
#endif
        print("-->>", sourceView.transform)
        send()
    }
    
    private func zoom(to aspectMode: AspectMode, animated: Bool) {
        let w = originSourceViewFrame.width
        let h = originSourceViewFrame.height
        let a = sourceView.transform.angle
        let width  = w * abs(cos(a)) + h * abs(sin(a))
        let height = w * abs(sin(a)) + h * abs(cos(a))
        let wRatio = frame.width / width
        let hRatio = frame.height / height
        let scale: CGFloat
        switch aspectMode {
        case .fill:
            scale = max(wRatio, hRatio)
        case .fit:
            scale = min(wRatio, hRatio)
        }
        zoomToScale(scale, animated: animated)
#if targetEnvironment(macCatalyst)
        UIView.animate(withDuration: 0.24) {
            self.dragView.transform = .identity
        }
#endif
    }
    
    private func send() {
        delegate?.transformingSceneView(self)
    }
    
    // MARK: -
    
#if targetEnvironment(macCatalyst)
    
    @objc private func hoverGestureRecognizeHandler(_ sender: UIHoverGestureRecognizer) {
        // TODO: -
    }
    
#endif
    
    @objc private func longPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
#if targetEnvironment(macCatalyst)
        if mode == .undefined {
            sender.reset()
            return
        }
#endif
        switch sender.state {
        case .began:
            let point = sender.location(in: sourceView)
            let isContains = sourceView.layer.contains(point)
            if !isContains {
                sender.reset()
                return
            }
#if targetEnvironment(macCatalyst)
            originA = sender.location(in: sender.view)
            originLine = Line(a: anchor, b: originA!)
            dragOriginTransform = dragView.transform
#else
            originA = sender.safeLocation(ofTouch: 0, in: sender.view)
            originB = sender.safeLocation(ofTouch: 1, in: sender.view)
#endif
            originTransform = sourceView.transform
        case .changed:
#if targetEnvironment(macCatalyst)
            currentA = sender.location(in: sender.view)
            currentLine = Line(a: anchor, b: currentA!)
#else
            currentA = sender.safeLocation(ofTouch: 0, in: sender.view)
            currentB = sender.safeLocation(ofTouch: 1, in: sender.view)
#endif
            calculate()
        default:
            break
        }
    }
}

// MARK: - Extensions -

private extension UIGestureRecognizer {
    
    // MARK: -
    
    func safeLocation(ofTouch touch: Int, in view: UIView?) -> CGPoint? {
        if touch < numberOfTouches {
            return location(ofTouch: touch, in: view)
        }
        return nil
    }
    
    func reset() {
        isEnabled = false
        isEnabled = true
    }
}

// MARK: -

private extension CGPoint {
    
    // MARK: -
    
    func parametricLineFunction(with t: CGFloat, to point: CGPoint) -> CGPoint {
        let l = point.x - x
        let m = point.y - y
        return CGPoint(
            x: l * t + x,
            y: m * t + y
        )
    }
}

// MARK: -

private typealias Vector = CGPoint

// MARK: -

private struct Line {
    
    // MARK: -
    
    var a: CGPoint
    var b: CGPoint
    
    // MARK: -
    
    var center: CGPoint {
        return a.parametricLineFunction(with: 0.5, to: b)
    }
    
    var vector: Vector {
        return CGPoint(
            x: b.x - a.x,
            y: b.y - a.y
        )
    }
    
    // MARK: -
    
    init(a: CGPoint, b: CGPoint) {
        self.a = a
        self.b = b
    }
    
    // MARK: -
    
    func angle(to line: Line) -> CGFloat {
        let vector1 = vector
        let vector2 = line.vector
        let sign = vector1.x * vector2.y - vector1.y * vector2.x > 0.0 ? -1.0 : +1.0
        return sign * acos(vector1 * vector2 / (vector1.length * vector2.length))
    }
}

// MARK: -

private extension Vector {
    
    // MARK: -
    
    static func * (lhs: Vector, rhs: Vector) -> CGFloat {
        return lhs.x * rhs.x + lhs.y * rhs.y
    }
    
    // MARK: -
    
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

// MARK: -

private extension CGFloat {
    
    // MARK: -
    
    var radians: CGFloat {
        return self * .pi / 180.0
    }
    
    var degrees: CGFloat {
        return self * 180.0 / .pi
    }
}

// MARK: -

private extension CGPoint {
    
    // MARK: -
    
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(
            x: lhs.x * rhs,
            y: lhs.y * rhs
        )
    }
}
