//
//  RadioButton.swift
//  FlipPad
//
//  Created by Alex on 01.04.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit

class RadioButton: CheckBox {
    
    override var checkedImage: UIImage? {
        return UIImage(named: "checkedRadioButton")
    }
    
    override var uncheckedImage: UIImage? {
        return UIImage(named: "uncheckedRadioButton")
    }
    
}
