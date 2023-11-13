//
//  FooterView.swift
//  FlipPad
//
//  Created by Alex on 2/18/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import UIKit

class FooterView: UIView {
    
    public var title: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }
    
    public var isCustomHidden: Bool {
        get {
            !hideButton.isHidden
        }
        set {
            hideButton.isHidden = !newValue
        }
    }
    
    private lazy var label: UILabel = {
        let result = UILabel()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.textAlignment = .center
        result.numberOfLines = 1
        result.lineBreakMode = .byTruncatingMiddle
        result.font = UIFont.systemFont(ofSize: 11, weight: .light)
        result.textColor = .black
        return result
    }()
    
    private lazy var stackView: UIStackView = {
        let result = UIStackView()
        result.axis = .horizontal
        result.spacing = 2.0
        result.alignment = .center
        return result
    }()
    
    private lazy var hideButton: UIButton = {
        let result = UIButton()
        result.setImage(UIImage(named: "hidden_selected"), for: .normal)
        // result.setImage(UIImage(named: "hidden_selected"), for: .selected)
        result.tintColor = .black
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .white
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(hideButton)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: .left,
                relatedBy: .equal,
                toItem: stackView,
                attribute: .left,
                multiplier: 1.0,
                constant: -2.0
            )
        )
        addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: .right,
                relatedBy: .equal,
                toItem: stackView,
                attribute: .right,
                multiplier: 1.0,
                constant: 2.0
            )
        )
        addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: .top,
                relatedBy: .equal,
                toItem: stackView,
                attribute: .top,
                multiplier: 1.0,
                constant: 0.0
            )
        )
        addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: stackView,
                attribute: .centerY,
                multiplier: 1.0,
                constant: 0.0
            )
        )
        hideButton.addConstraint(
            NSLayoutConstraint(
                item: hideButton,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 12.0
            )
        )
        hideButton.addConstraint(
            NSLayoutConstraint(
                item: hideButton,
                attribute: .width,
                relatedBy: .equal,
                toItem: hideButton,
                attribute: .height,
                multiplier: 1.625,
                constant: 0.0
            )
        )
    }
}
