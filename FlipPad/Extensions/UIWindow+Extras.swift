//
//  UIWindow+Extras.swift
//  FlipPad
//
//  Created by zuzex on 05.12.2022.
//  Copyright © 2022 Alex. All rights reserved.
//

import Foundation
import UIKit

public extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(self.rootViewController)
    }
    
    static func getVisibleViewControllerFrom(_ vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else if let sc = vc as? UISplitViewController {
            let controller = sc.isCollapsed ? sc.viewControllers.first : sc.viewControllers.last
            return UIWindow.getVisibleViewControllerFrom(controller)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(pvc)
            } else {
                return vc
            }
        }
    }
}
