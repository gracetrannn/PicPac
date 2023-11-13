//
//  LoaderOperation.swift
//

import Foundation

class LoaderOperation: AsyncOperation {
    
    let loader: Loader
    
    let animated: Bool
    
    let block: Loader.LoaderBlock?
    
    init(loader: Loader, animated: Bool, block: Loader.LoaderBlock?) {
        self.loader = loader
        self.animated = animated
        self.block = block
    }
}
