//
// DraggableView.swift
//

import UIKit

class DraggableView: UIControl, UIGestureRecognizerDelegate {
    
    // MARK: -
    
    private var delta = CGSize.zero
    
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
    
    func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Empty.
    }
    
    func repositionIfNeeded(_ animated: Bool = true) {
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
                self.sendActions(for: .valueChanged)
            }
        } else {
            layer.position = position
        }
    }
    
    // MARK: -
    
    private func setup() {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: #selector(panGestureRecognizerHandler(_:)))
        addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: -
    
    @objc private func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            let location = sender.location(in: self)
            delta = CGSize(
                width: location.x - 0.5 * bounds.width,
                height: location.y - 0.5 * bounds.height
            )
            setHighlighted(true, animated: true)
        case .changed:
            guard let superview = superview else {
                return
            }
            let location = sender.location(in: superview)
            layer.position = CGPoint(
                x: location.x - delta.width,
                y: location.y - delta.height
            )
            sendActions(for: .valueChanged)
        default:
            setHighlighted(false, animated: true)
            repositionIfNeeded()
        }
    }
}
