//
//  DisplayTimeAsyncOperation.swift
//  Loader
//
//  Created by Vladimir Psyukalov on 23.04.2021.
//

import Foundation

class DisplayTimeAsyncOperation: AsyncOperation {
    
    let minDisplayTime: TimeInterval
    
    init(minDisplayTime: TimeInterval) {
        self.minDisplayTime = minDisplayTime
    }
    
    override func main() {
        DispatchQueue.main.asyncAfter(deadline: .now() + minDisplayTime) { [weak self] in
            guard let self = self else {
                return
            }
            self.state = .isFinished
        }
    }
}
