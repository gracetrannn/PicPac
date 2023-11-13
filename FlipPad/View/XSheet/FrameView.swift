//
//  FrameView.swift
//  FlipPad
//
//  Created by Alex on 2/17/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import UIKit

class FrameView: UIView {
    
    enum FrameType {
        
        case empty
        case clear
        case content
    }
    
    // MARK: -
    
    var type = FrameType.empty {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var isCustomHidden = false {
        didSet {
            hiddenOverlayView.isHidden = !isCustomHidden
        }
    }
    
    var isLocked = false {
        didSet {
            lockedOverlayView.isHidden = !isLocked
        }
    }
    
    // MARK: -
    
    private lazy var pencilImageView: UIImageView = {
        let result = UIImageView()
        result.clipsToBounds = true
        result.translatesAutoresizingMaskIntoConstraints = false
        result.contentMode = .scaleToFill
        result.clipsToBounds = true
        return result
    }()
    
    private lazy var paintImageView: UIImageView = {
        let result = UIImageView()
        result.clipsToBounds = true
        result.translatesAutoresizingMaskIntoConstraints = false
        result.contentMode = .scaleToFill
        result.clipsToBounds = true
        return result
    }()
    
    private lazy var hiddenOverlayView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        result.translatesAutoresizingMaskIntoConstraints = false
        result.backgroundColor = .red.withAlphaComponent(0.6)
        return result
    }()
    
    private lazy var lockedOverlayView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        result.translatesAutoresizingMaskIntoConstraints = false
        result.backgroundColor = .red.withAlphaComponent(0.2)
        return result
    }()
    
    // MARK: -
    
    init(frame: CGRect, cell: FBCell) {
        super.init(frame: frame)
        configure(with: cell)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.separatorColor.withAlphaComponent(0.6).cgColor)
        context?.setLineWidth(0.5)
        switch type {
        case .clear:
            context?.addLines(between: [
                CGPoint(x: 0.0, y: 0.0),
                CGPoint(x: frame.width, y: frame.height)
            ])
            context?.addLines(between: [
                CGPoint(x: 0.0, y: frame.height),
                CGPoint(x: frame.width, y: 0.0)
            ])
        case .empty:
            context?.addLines(between: [
                CGPoint(x: frame.width / 2.0, y: 0.0),
                CGPoint(x: frame.width / 2.0, y: frame.height)
            ])
        case .content:
            break
        }
        context?.strokePath()
    }
    
    // MARK: -
    
    private func configure(with cell: FBCell) {
        clipsToBounds = true
        addSubview(paintImageView)
        paintImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        paintImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        paintImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        paintImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        paintImageView.image = cell.paintImage?.previewUiImage
        addSubview(pencilImageView)
        pencilImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        pencilImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        pencilImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        pencilImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        pencilImageView.image = cell.pencilImage?.previewUiImage
        addSubview(lockedOverlayView)
        lockedOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lockedOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        lockedOverlayView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        lockedOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        addSubview(hiddenOverlayView)
        hiddenOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        hiddenOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        hiddenOverlayView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        hiddenOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        isCustomHidden = false
        isLocked = false
        unlightboxHighlight()
    }
    
    // MARK: -
    
    func lightboxHighlight() {
        backgroundColor = .selectionColor
    }
    
    func unlightboxHighlight() {
        backgroundColor = .white
    }
    
    func flash() {
        let color = lockedOverlayView.backgroundColor
        UIView.animate(withDuration: 0.5) {
            self.lockedOverlayView.backgroundColor = .red.withAlphaComponent(0.5)
        } completion: { _ in
            UIView.animate(withDuration: 0.5) {
                self.lockedOverlayView.backgroundColor = color
            }
        }
    }
    
    func getImages() -> [UIImage?] {
        return [
            pencilImageView.image,
            paintImageView.image
        ]
    }
    
    func setImages(pencil: UIImage?, paint: UIImage?) {
        pencilImageView.image = pencil
        paintImageView.image = paint
    }
}
