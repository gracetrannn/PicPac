//
//  UIToolbar+Extras.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/2/22.
//  Copyright © 2022 Alex. All rights reserved.
//

import UIKit

extension UIToolbar {
    
    var buttonSubviews: [UIView] {
        let stackView = subviews.first(where: { subview in
            return String(describing: type(of: subview)) == "_UIToolbarContentView"
        })?.subviews.first(where: { subview in
            return String(describing: type(of: subview)) == "_UIButtonBarStackView"
        }) as? UIStackView
        
        return stackView?.arrangedSubviews.filter({
            return String(describing: type(of: $0)) == "_UIButtonBarButton"
        }).map({ $0.subviews.first! }) ?? []
    }
    
}
