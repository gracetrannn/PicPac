//
// FBBrushCircleView.swift
//

import UIKit

@objc protocol FBBrushCircleViewDelegate: NSObjectProtocol {
    
    func brushCircleViewDidChangePosition(_ brushCircleView: FBBrushCircleView)
}

@objc class FBBrushCircleView: UIControl {
    
    // MARK: -
    
    private enum Mode {
        
        case undefined, size, alpha
    }
    
    // MARK: -
    
    private var lineWidth: CGFloat {
        return 16.0
    }
    
    private var opacity: Float {
        return 0.12
    }
    
    private var strokeColor: CGColor {
        return UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0).cgColor
    }
    
    private var hardLineColor: CGColor {
        return UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor
    }
    
    private var delta: CGFloat {
        return 128.0
    }
    
    private var minIncrement: CGFloat {
        return 0.002
    }
    
    private var maxIncrement: CGFloat {
        return 0.032
    }
    
    private var minUiAlpha: Float {
        return 0.08
    }
    
    private var maxUiAlpha: Float {
        return 1.0
    }
    
    private var minUiSize: CGFloat {
        return 1.0
    }
    
    private var maxUiSize: CGFloat {
        return swipeFrame.width
    }
    
    private var swipeFrame: CGRect {
        return CGRect(
            x: lineWidth,
            y: lineWidth,
            width: bounds.width - 2.0 * lineWidth,
            height: bounds.height - 2.0 * lineWidth
        )
    }
    
    // MARK: -
    
    @objc weak var delegate: FBBrushCircleViewDelegate?
    
    @objc var sizeRatio: CGFloat {
        get {
            return _sizeRatio
        }
        set {
            _sizeRatio = newValue.normalized
        }
    }
    
    @objc var alphaRatio: CGFloat {
        get {
            return _alphaRatio
        }
        set {
            _alphaRatio = newValue.normalized
        }
    }
    
    @objc var color: UIColor {
        get {
            return colorLayer.color
        }
        set {
            colorLayer.color = newValue
        }
    }
    
    // MARK: -
    
    private var _sizeRatio: CGFloat = 0.5 {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var _alphaRatio: CGFloat = 1.0 {
        didSet {
            colorLayer.opacity = Float(_alphaRatio) * (maxUiAlpha - minUiAlpha) + minUiAlpha
        }
    }
    
    // MARK: -
    
    private var strokeLayer = EllipseLayer()
    private var colorLayer = EllipseLayer()
    private var hardLineStrokeLayer = EllipseLayer()
    
    private var dragView = MaskedTouchView()
    private var swipeView = MaskedTouchView()
    
    private var swipeOrigin = CGPoint.zero
    
    private var dragDelta = CGSize.zero
    
    private var mode = Mode.undefined
    
    private var timer: Timer?
    
    private var sign: CGFloat = 1.0
    private var x: CGFloat = 0.0
    
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
        CALayer.performWithoutAnimation {
            let swipeFrame = self.swipeFrame
            dragView.frame = bounds
            swipeView.frame = swipeFrame
            strokeLayer.frame = CGRect(
                x: 0.5 * lineWidth,
                y: 0.5 * lineWidth,
                width: bounds.width - lineWidth,
                height: bounds.height - lineWidth
            )
            let value = _sizeRatio * (maxUiSize - minUiSize) + minUiSize
            let inset = 0.5 * (maxUiSize - value)
            colorLayer.frame = swipeFrame.insetBy(dx: inset, dy: inset)
            hardLineStrokeLayer.frame = swipeFrame
        }
    }
    
    // MARK: -
    
    private func setup() {
        backgroundColor = .clear
        addSubview(dragView)
        addSubview(swipeView)
        let dragPanGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(dragViewGestureRecognizerHandler(_:))
        )
        let swipePanGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(swipeViewGestureRecognizerHandler(_:))
        )
        dragView.addGestureRecognizer(dragPanGestureRecognizer)
        swipeView.addGestureRecognizer(swipePanGestureRecognizer)
        strokeLayer.fillColor = UIColor.white.cgColor
        strokeLayer.strokeColor = strokeColor
        strokeLayer.shadowColor = UIColor.black.cgColor
        strokeLayer.shadowOffset = .zero
        strokeLayer.shadowOpacity = opacity
        strokeLayer.lineWidth = lineWidth
        colorLayer.fillColor = UIColor.green.cgColor
        hardLineStrokeLayer.fillColor = UIColor.clear.cgColor
        hardLineStrokeLayer.strokeColor = hardLineColor
        hardLineStrokeLayer.lineWidth = 1.0
        layer.addSublayer(strokeLayer)
        layer.addSublayer(colorLayer)
        layer.addSublayer(hardLineStrokeLayer)
    }
    
    private func start() {
        timer = Timer(
            timeInterval: 0.02,
            target: self,
            selector: #selector(timerHandler),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer!, forMode: .default)
    }
    
    private func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func proceed(_ delta: CGFloat) {
        let absDelta = abs(delta)
        let value = easeIn(absDelta <= self.delta ? absDelta / self.delta : 1.0)
        sign = delta <= 0.0 ? -1.0 : +1.0
        x = value * (maxIncrement - minIncrement) + minIncrement
    }
    
    private func easeIn(_ x: CGFloat) -> CGFloat {
        return sin((x * .pi) / 2.0)
    }
    
    private func repositionIfNeeded(_ animated: Bool = true) {
        defer {
            delegate?.brushCircleViewDidChangePosition(self)
        }
        guard let superview = superview else {
            return
        }
        let center = CGSize(
            width: 0.5 * bounds.width,
            height: 0.5 * bounds.height
        )
        var position = layer.position
        if frame.minX < superview.bounds.minX {
            position.x = center.width
        }
        if frame.minY < superview.bounds.minY {
            position.y = center.height
        }
        if frame.maxX > superview.bounds.maxX {
            position.x = superview.bounds.width - center.width
        }
        if frame.maxY > superview.bounds.maxY {
            position.y = superview.bounds.height - center.height
        }
        if position == layer.position {
            return
        }
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layer.position = position
            } completion: { _ in
                self.delegate?.brushCircleViewDidChangePosition(self)
            }
        } else {
            layer.position = position
        }
    }
    
    // MARK: -
    
    @objc private func timerHandler() {
        switch mode {
        case .undefined:
            return
        case .size:
            _sizeRatio = (_sizeRatio + sign * x).normalized
        case .alpha:
            _alphaRatio = (_alphaRatio + -sign * x).normalized
        }
    }
    
    @objc private func dragViewGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            let location = sender.location(in: dragView)
            dragDelta = CGSize(
                width: location.x - 0.5 * bounds.width,
                height: location.y - 0.5 * bounds.height
            )
        case .changed:
            guard let superview = superview else {
                return
            }
            let location = sender.location(in: superview)
            layer.position = CGPoint(
                x: location.x - dragDelta.width,
                y: location.y - dragDelta.height
            )
        default:
            repositionIfNeeded()
        }
    }
    
    @objc private func swipeViewGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: sender.view)
        switch sender.state {
        case .began:
            swipeOrigin = location
        case .changed:
            let deltaX = swipeOrigin.x - location.x
            let deltaY = swipeOrigin.y - location.y
            switch mode {
            case .undefined:
                mode = abs(deltaX) < abs(deltaY) ? .size : .alpha
                start()
            case .size:
                proceed(deltaY)
            case .alpha:
                proceed(deltaX)
            }
        default:
            mode = .undefined
            stop()
            sendActions(for: .valueChanged)
        }
    }
}

fileprivate class MaskedTouchView: UIView {
    
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return UIBezierPath(ovalIn: bounds).contains(point)
    }
    
    // MARK: -
    
    private func setup() {
        backgroundColor = .clear
    }
}

fileprivate class EllipseLayer: CAShapeLayer {
    
    // MARK: - Colored
    
    var color: UIColor {
        get {
            if let fillColor = fillColor {
                return UIColor(cgColor: fillColor)
            }
            return .clear
        }
        set {
            fillColor = newValue.cgColor
        }
    }
    
    // MARK: - Internal override init
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(layer: Any) {
        let copy = layer as? EllipseLayer
        super.init(layer: layer)
        self.color = copy?.color ?? .clear
        setup()
    }
    
    // MARK: - Internal override func
    
    override func layoutSublayers() {
        super.layoutSublayers()
        path = CGPath(ellipseIn: bounds, transform: nil)
    }
    
    // MARK: - Private func
    
    private func setup() {
        color = .clear
    }
}

fileprivate extension CALayer {
    
    // MARK: - Public static func
    
    static func performWithoutAnimation(_ block: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        block()
        CATransaction.commit()
    }
}

fileprivate extension CGFloat {
    
    // MARK: -
    
    var normalized: CGFloat {
        if self < 0.0 {
            return 0.0
        }
        if self > 1.0 {
            return 1.0
        }
        return self
    }
}
