//
//  FBSlideView.swift
//  FlipPad
//
//  Created by Igor on 23.06.2022.
//  Copyright © 2022 Alex. All rights reserved.
//

import UIKit

@objc protocol FBSlideViewDataSource: NSObjectProtocol {
    
    func numberOfColumndsForSlideView(_ slideView: FBSlideView) -> Int
}

@objc protocol FBSlideViewDelegate: NSObjectProtocol {
    
    func slideViewDidBakeConstraints(_ slideView: FBSlideView)
}

@objc class FBSlideView: UIView {
    
    // MARK: - Side enum -
    @objc enum Side: Int, RawRepresentable {
        
        case right
        case left
        
        public var rawValue: RawValue {
            switch self {
            case .right:
                return 0
            case .left:
                return 1
            }
        }
    }
    
    @objc public var firstLineWidth: CGFloat = 40.0
    @objc public var cellWidth: CGFloat = 80.0
    
    @objc public weak var dataSource: FBSlideViewDataSource?
    
    @objc public weak var delegate: FBSlideViewDelegate?
    
    @objc public private(set) var side = Side.right
    
    private var leadingConst: CGFloat = 0.0
    private var trailingConst: CGFloat = 0.0
    
    // MARK: - private properties -
    private var leadingConstraint : NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var beginXPosition    : CGFloat = 0
    private let stackView = UIStackView()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var thumbView: UIView = {
        let thumbView = UIView()
        thumbView.backgroundColor = .black
        thumbView.offTamic()
        thumbView.layer.cornerRadius = 2
        return thumbView
    }()
    
    private lazy var captureView: UIView = {
        
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.offTamic()
        containerView.addGestureRecognizer(panGesture)
        containerView.addSubview(thumbView)
        
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 20),
            thumbView.widthAnchor.constraint(equalToConstant: 4),
            thumbView.heightAnchor.constraint(equalToConstant: 40),
            thumbView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 0),
            thumbView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 0)
        ])
        
        return containerView
    }()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
    }()
    
    @objc public var isClosed = false {
        didSet {
            leadingConstraint?.constant  = isClosed ? -width : -leadingConst
            trailingConstraint?.constant = isClosed ? +width : +trailingConst
        }
    }
    
    private var width: CGFloat {
        return containerView.frame.width - 0.0
    }
    
    // MARK: - initial -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    // MARK: - private methods -
    
    private func initialSetup() {
        
        self.offTamic()
        
        // Setup stack view
        
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.offTamic()
        self.addSubview(stackView)
        
        // Setup stack view constraints
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor,
                                           constant: 0),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                              constant: 0),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                               constant: 0),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                                constant: 0)
        ])
    }
    
    private func clearStackView() {
        stackView.removeArrangedSubview(containerView)
        stackView.removeArrangedSubview(captureView)
        containerView.removeFromSuperview()
        captureView.removeFromSuperview()
    }
    
    private func createView(at side: Side) {
        self.side = side
        self.clearStackView()
        switch side {
        case .left:
            self.stackView.addArrangedSubview(containerView)
            self.stackView.addArrangedSubview(captureView)
        case .right:
            self.stackView.addArrangedSubview(captureView)
            self.stackView.addArrangedSubview(containerView)
        }
    }
    
    private func add(toContainerView subview: UIView) {
        self.containerView.subviews.forEach { $0.removeFromSuperview() }
        subview.offTamic()
        self.containerView.addSubview(subview)
        
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: self.containerView.topAnchor,
                                         constant: 0),
            subview.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor,
                                            constant: 0),
            subview.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor,
                                             constant: 0),
            subview.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor,
                                              constant: 0),
            subview.heightAnchor.constraint(equalTo: self.containerView.heightAnchor,
                                            constant: 0)
        ])
    }
    
    private func bakeConstraints() {
        leadingConstraint?.constant = frame.minX
        trailingConstraint?.constant = frame.maxX - (superview?.frame.width ?? 0.0)
        delegate?.slideViewDidBakeConstraints(self)
    }
    
    @objc private func panGestureAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.thumbView.alpha = 1.0
            beginXPosition = self.center.x
        case .changed:
            switch side {
            case .right:
                if let superview = superview {
                    var newX = beginXPosition + sender.translation(in: captureView).x
                    if newX > superview.frame.width + self.frame.width/2 - captureView.frame.width {
                        newX = superview.frame.width + self.frame.width/2 - captureView.frame.width
                    } else if newX < superview.frame.width - self.frame.width/2 {
                        newX = superview.frame.width - self.frame.width/2
                    }
                    self.center = CGPoint(x: newX,
                                          y: self.center.y)
                }
            case .left:
                var newX = beginXPosition + sender.translation(in: captureView).x
                if newX > self.frame.width/2 {
                    newX = self.frame.width/2
                } else if newX < -self.frame.width/2 + captureView.frame.width {
                    newX = -self.frame.width/2 + captureView.frame.width
                }
                self.center = CGPoint(x: newX,
                                      y: self.center.y)
                
            }
        case .ended:
            moveToNearestLevel()
        default:
            break
        }
    }
    
    private func getNearestX() -> [CGFloat] {
        var result: [CGFloat]
        switch side {
        case .right:
            result = []
            for i in 1...(dataSource?.numberOfColumndsForSlideView(self) ?? 0) {
                result.append(CGFloat(i) * cellWidth)
            }
            result.append(result.last! + firstLineWidth)
            result.append(0.0)
            result = result.map { (superview?.frame.width ?? 0.0) + $0 }
        case .left:
            result = [0.0, firstLineWidth]
            for i in 1...(dataSource?.numberOfColumndsForSlideView(self) ?? 0) {
                result.append(firstLineWidth + CGFloat(i) * cellWidth)
            }
            result = result.map { -1.0 * $0 }
        }
        return result
    }
    
    @objc public func moveToNearestLevel() {
        let nearestsX = getNearestX()
        let x: CGFloat
        let delta: CGFloat
        switch side {
        case .right:
            x = nearestsX.min { abs($0 - frame.maxX) < abs($1 - frame.maxX) }!
            delta = x - frame.maxX
        case .left:
            x = nearestsX.min { abs($0 - frame.minX) < abs($1 - frame.minX) }!
            delta = -(frame.minX - x)
        }
        UIView.animate(withDuration: 0.15) {
            self.center = CGPoint(
                x: self.center.x + delta,
                y: self.center.y
            )
        } completion: { _ in
            let const = self.side == .left ? abs(self.frame.minX) : abs(self.frame.maxX - (self.superview?.frame.width ?? 0.0))
            self.isClosed = abs(const) == self.width
            self.bakeConstraints()
            self.updateConsts()
        }
    }
    
    private func updateConsts() {
        // if it's closed then next show is full.
        leadingConst = isClosed ? 0.0 : abs(frame.minX)
        trailingConst = isClosed ? 0.0 : abs(frame.maxX - (superview?.frame.width ?? 0.0))
    }
    
    // MARK: - public methods -
    
    /// Setup slideView in view(container such as sceneScrollView), with subview(view such as xsheet), side(left/right)
    @objc public func setup(in view: UIView, with subview: UIView, at side: Side, isClosed: Bool) {
        self.removeFromSuperview()
        self.isClosed = isClosed
        view.addSubview(self)
        self.leadingConstraint = self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: isClosed ? -width : 0)
        self.trailingConstraint = self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: isClosed ? width : 0)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        switch side {
        case .right:
            self.leadingConstraint?.isActive  = false
            self.trailingConstraint?.isActive = true
        case .left:
            self.trailingConstraint?.isActive = false
            self.leadingConstraint?.isActive  = true
        }
        createView(at: side)
        add(toContainerView: subview)
    }
    
    /// Update view attach side
    @objc public func update(side: Side) {
        if self.side == side {
            return
        }
        createView(at: side)
        switch side {
        case .right:
            self.leadingConstraint?.isActive  = false
            self.trailingConstraint?.isActive = true
        case .left:
            self.trailingConstraint?.isActive = false
            self.leadingConstraint?.isActive  = true
        }
        leadingConstraint?.constant = isClosed ? -width : 0.0
        trailingConstraint?.constant = isClosed ? width : 0.0
        leadingConst = abs(leadingConstraint?.constant ?? 0.0)
        trailingConst = abs(trailingConstraint?.constant ?? 0.0)
    }
    
    /// Present slideView
    @objc func show() {
        self.thumbView.alpha = 1.0
        switch side {
        case .right:
            trailingConstraint?.constant = +trailingConst
            UIView.animate(withDuration: 0.15) {
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.isClosed = false
                self.bakeConstraints()
            }
        case .left:
            leadingConstraint?.constant = -leadingConst
            UIView.animate(withDuration: 0.15) {
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.isClosed = false
                self.bakeConstraints()
            }
        }
    }
    
    ///Dismiss slideView
    @objc func hide() {
        switch side {
        case .right:
            trailingConstraint?.constant = +width
            UIView.animate(withDuration: 0.15) {
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.isClosed = true
                self.bakeConstraints()
                UIView.animate(withDuration: 0.7, delay: 2) {
                    self.thumbView.alpha = 0.0
                }
            }
        case .left:
            leadingConstraint?.constant = -width
            UIView.animate(withDuration: 0.15) {
                self.superview?.layoutIfNeeded()
            } completion: { _ in
                self.isClosed = true
                self.bakeConstraints()
                UIView.animate(withDuration: 0.7, delay: 2) {
                    self.thumbView.alpha = 0.0
                }
            }
        }
    }
}
