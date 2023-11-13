//
//  PlaybackToolbarView.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/2/22.
//  Copyright © 2022 Alex. All rights reserved.
//

import UIKit

@objc class PlaybackToolbarView: FloatingToolbarView {
    
    @objc let slider = { () -> UISlider in
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.0
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = UIColor.systemBlue
        return slider
    }()
        
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
        toolbar.items = items
        toolbar.layoutSubviews()
        self.refreshTransform()
    }
    
    @objc var items: [UIBarButtonItem] {
        return toolbar.items ?? []
    }
    
    override func configure(_ length: CGFloat) {
        super.configure(length)
        
        let height = Config.isPhone ? 28.0 : 40.0
        
        addSubview(toolbar)
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo: toolbar.leftAnchor),
            rightAnchor.constraint(equalTo: toolbar.rightAnchor),
            topAnchor.constraint(equalTo: toolbar.topAnchor, constant: -6.0),
            toolbar.heightAnchor.constraint(equalToConstant: height)
        ])
        
        if UIDevice.current.userInterfaceIdiom != .phone {
            addSubview(slider)
            NSLayoutConstraint.activate([
                leftAnchor.constraint(equalTo: slider.leftAnchor, constant: -16.0),
                rightAnchor.constraint(equalTo: slider.rightAnchor, constant: 16.0),
                bottomAnchor.constraint(equalTo: slider.bottomAnchor, constant: 4.0),
                toolbar.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: 0.0)
            ])
        } else {
            bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 6.0).isActive = true
        }
    }
    
}
