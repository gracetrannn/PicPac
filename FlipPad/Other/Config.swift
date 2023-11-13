//
//  Config.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/18/22.
//  Copyright © 2022 Alex. All rights reserved.
//

import UIKit

@objc class Config: NSObject {
    
    @objc static let DGC: Bool = {
        return false
    }()
    
    // MARK: - UI Features
    
    @objc static let floatingToolbars: Bool = {
        /*
        return isMac || !isPhone
         */
        return true
    }()
        
}

@objc extension Config {
    
    @objc static var isMac: Bool {
#if targetEnvironment(macCatalyst)
    return true
#else
    return false
#endif
    }
    
    @objc static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
}
