//
//  UIWindow+Loader.swift
//  Loader
//
//  Created by Vladimir Psyukalov on 23.04.2021.
//

import UIKit

extension UIWindow {
    
    static var main: UIWindow? {
        let application = UIApplication.shared
        var result: UIWindow?
        if let window = application.delegate?.window {
            result = window
        }
        if #available(iOS 13.0, *) {
            if let sceneWindow = (application.connectedScenes.first?.delegate as? DocumentsSceneDelegate)?.window {
                result = sceneWindow
            }
        }
        return result
    }
    
    static var loader: Loader? {
        guard let main = main else {
            return nil
        }
        for subview in main.subviews {
            if let loader = subview as? Loader {
                return loader
            }
        }
        return nil
    }
}
