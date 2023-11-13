//
//  Loader.swift
//

import UIKit

public class Loader: UIView {
    
    public typealias LoaderBlock = () -> Void
    
    // MARK: - Static public var
    
    static public var style = UIActivityIndicatorView.Style.white
    
    static public var backgroundColor = UIColor.black.withAlphaComponent(0.2)
    static public var containerBackgroundColor = UIColor.white
    static public var activityIndicatorColor = UIColor.gray
    
    static public var minDisplayTime: TimeInterval = 0.8
    static public var duration: TimeInterval = 0.2
    
    static public var margin: CGFloat = 16.0
    static public var cornerRadius: CGFloat = 8.0
    
    // MARK: - Internal let
    
    let containerView = UIView()
    
    let activityIndicatorView = UIActivityIndicatorView(style: Loader.style)
    
    // MARK: - Private let
    
    private let operationQueue = OperationQueue.main
    
    // MARK: - Public override init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Public func
    
    public func show(animated: Bool = true, block: LoaderBlock? = nil) {
        operationQueue.addOperation(ShowLoaderOperation(loader: self, animated: animated, block: block))
        let time = Loader.minDisplayTime
        if time > 0.0 {
            operationQueue.addOperation(DisplayTimeAsyncOperation(minDisplayTime: time))
        }
    }
    
    public func hide(animated: Bool = true, block: LoaderBlock? = nil) {
        operationQueue.addOperation(HideLoaderOperation(loader: self, animated: animated, block: block))
    }
    
    // MARK: - Private func
    
    private func setup() {
        alpha = 0.0
        isHidden = true
        backgroundColor = Loader.backgroundColor
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        setupOperationQueue()
        setupContainerView()
        setupActivityIndicatorView()
        setupContainerViewLayoutConstraints()
        setupActivityIndicatorViewLayoutConstraints()
    }
    
    private func setupOperationQueue() {
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    private func setupContainerView() {
        containerView.layer.cornerRadius = Loader.cornerRadius
        containerView.layer.masksToBounds = true
        containerView.alpha = 0.0
        containerView.backgroundColor = Loader.containerBackgroundColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicatorView)
    }
    
    private func setupActivityIndicatorView() {
        activityIndicatorView.color = Loader.activityIndicatorColor
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupContainerViewLayoutConstraints() {
        let centerX = NSLayoutConstraint(
            item: containerView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
        )
        let centerY = NSLayoutConstraint(
            item: containerView,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0.0
        )
        addConstraint(centerX)
        addConstraint(centerY)
    }
    
    private func setupActivityIndicatorViewLayoutConstraints() {
        let top = NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .top,
            relatedBy: .equal,
            toItem: containerView,
            attribute: .top,
            multiplier: 1.0,
            constant: Loader.margin
        )
        let left = NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .left,
            relatedBy: .equal,
            toItem: containerView,
            attribute: .left,
            multiplier: 1.0,
            constant: Loader.margin
        )
        let centerX = NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: containerView,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0.0
        )
        let centerY = NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: containerView,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0.0
        )
        containerView.addConstraint(top)
        containerView.addConstraint(left)
        containerView.addConstraint(centerX)
        containerView.addConstraint(centerY)
    }
}
