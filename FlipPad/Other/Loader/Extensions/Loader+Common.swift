//
//  Loader+Common.swift
//  Loader
//
//  Created by Vladimir Psyukalov on 23.04.2021.
//

import UIKit

public extension Loader {
    
    static func show(animated: Bool = true, block: LoaderBlock? = nil) {
        guard UIWindow.loader == nil else {
            return
        }
        guard let window = UIWindow.main else {
            return
        }
        let loader = Loader()
        let attributes: [NSLayoutConstraint.Attribute] = [
            .top,
            .right,
            .bottom,
            .left
        ]
        let constraints = attributes.map {
            NSLayoutConstraint(
                item: window,
                attribute: $0,
                relatedBy: .equal,
                toItem: loader,
                attribute: $0,
                multiplier: 1.0,
                constant: 0.0
            )
        }
        window.addSubview(loader)
        window.addConstraints(constraints)
        loader.show(animated: animated, block: block)
    }
    
    static func hide(animated: Bool = true, block: LoaderBlock? = nil) {
        guard let loader = UIWindow.loader else {
            return
        }
        loader.hide(animated: animated) {
            loader.removeFromSuperview()
            block?()
        }
    }
}
