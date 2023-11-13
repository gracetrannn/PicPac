//
//  ToolsToolbarView.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/2/22.
//  Copyright © 2022 Alex. All rights reserved.
//

import UIKit

@objc class ToolsToolbarView: FloatingToolbarView {
    
    private let toolbar = { () -> UIToolbar in
        let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 35.0)))
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        return toolbar
    }()

    //
    
    @objc init(items: [UIBarButtonItem], length: CGFloat) {
        super.init(frame: .zero)
        
        self.configure(length)
        self.setItems(items)
    }
    
    required init?(coder: NSCoder) {
        preconditionFailure("required init?(coder: NSCoder) is not supported")
    }
    
    @objc func setItems(_ items: [UIBarButtonItem]) {
        toolbar.setItems(items, animated: false)
        toolbar.layoutSubviews()
        self.refreshTransform()
    }
    
    @objc var items: [UIBarButtonItem] {
        return toolbar.items ?? []
    }
    
    override func refreshTransform() {
        switch orientation {
        case .horizontal:
            transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            for subview in toolbar.buttonSubviews {
                subview.transform = .identity
            }
        case .vertical:
            transform = CGAffineTransform(translationX: translation.x, y: translation.y).rotated(by: .pi / 2.0)
            for subview in toolbar.buttonSubviews {
                subview.transform = .init(rotationAngle: .pi / -2.0)
            }
        }
        correctFrame()
    }
    
    override func configure(_ length: CGFloat) {
        super.configure(length)
        let height = Config.isPhone ? 44.0 : 64.0
        heightAnchor.constraint(equalToConstant: height).isActive = true
        
        addSubview(toolbar)
        centerYAnchor.constraint(equalTo: toolbar.centerYAnchor).isActive = true
        leftAnchor.constraint(equalTo: toolbar.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: toolbar.rightAnchor).isActive = true
    }
    
}
