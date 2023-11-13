//
//  TouchLockingView.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 4/10/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import Foundation

class TouchLockingView: UIView {
    
    @objc weak var target: NSObject?
    @objc var action: Selector?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let action = action {
            target?.perform(action)
        }
    }
    
}
