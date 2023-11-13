//
//  HideLoaderOperation.swift
//

import UIKit

class HideLoaderOperation: LoaderOperation {
    
    override func main() {
        if loader.isHidden {
            state = .isFinished
            return
        }
        let alpha: CGFloat = 0.0
        if animated {
            UIView.animate(withDuration: Loader.duration, animations: {
                self.loader.containerView.alpha = alpha
            }) { _ in
                UIView.animate(withDuration: Loader.duration, animations: {
                    self.loader.alpha = alpha
                }) { _ in
                    self.loader.activityIndicatorView.stopAnimating()
                    self.loader.isHidden = true
                    print("Loader did hide animated;")
                    self.block?()
                    self.state = .isFinished
                }
            }
        } else {
            loader.containerView.alpha = alpha
            loader.alpha = alpha
            loader.activityIndicatorView.stopAnimating()
            loader.isHidden = true
            print("Loader did hide;")
            block?()
            state = .isFinished
        }
    }
}
