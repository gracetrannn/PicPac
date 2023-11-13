//
//  Checkbox.swift
//  FlipPad
//
//  Created by Alex on 01.04.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit

class CheckBox: UIButton {
    
    var checkedImage: UIImage? { UIImage(named: "checkedCheckbox") }
    var uncheckedImage: UIImage? { UIImage(named: "uncheckedCheckbox") }

    @objc var isChecked: Bool = false {
        didSet {
            if isChecked {
                self.setImage(checkedImage, for: .normal)
            } else {
                self.setImage(uncheckedImage, for: .normal)
            }
        }
    }
    
    var isReversingOnState: Bool = true

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.isChecked = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isReversingOnState {
            isChecked.toggle()
        } else {
            if !isChecked {
                isChecked = true
            }
        }
        
        super.touchesEnded(touches, with: event)
    }
    
}
