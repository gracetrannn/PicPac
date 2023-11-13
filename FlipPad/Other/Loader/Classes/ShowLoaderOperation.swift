//
//  ShowLoaderOperation.swift
//  Loader
//
//  Created by Vladimir Psyukalov on 23.04.2021.
//

import UIKit

class ShowLoaderOperation: LoaderOperation {
    
    override func main() {
        if !loader.isHidden {
            state = .isFinished
            return
        }
        let alpha: CGFloat = 1.0
        loader.isHidden = false
        loader.activityIndicatorView.startAnimating()
        if animated {
            UIView.animate(withDuration: Loader.duration, animations: {
                self.loader.alpha = alpha
            }) { _ in
                UIView.animate(withDuration: Loader.duration, animations: {
                    self.loader.containerView.alpha = alpha
                }) { _ in
                    print("Loader did show animated;")
                    self.block?()
                    self.state = .isFinished
                }
            }
        } else {
            loader.alpha = alpha
            loader.containerView.alpha = alpha
            print("Loader did show;")
            block?()
            state = .isFinished
        }
    }
}
