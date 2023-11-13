//
// Extensions.swift
//

import Foundation

extension UIViewController {
    
    // MARK: -
    
    static func instantiate() -> Self {
        return UIStoryboard(name: String(describing: self), bundle: nil).instantiateInitialViewController() as! Self
    }
    
    // MARK: -
    
    func wrapInNavigationController() -> UINavigationController {
        return UINavigationController(rootViewController: self)
    }
}

extension UIView {
    
    public func pushAnimate() {
        self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        } completion: { _ in }
    }
}
