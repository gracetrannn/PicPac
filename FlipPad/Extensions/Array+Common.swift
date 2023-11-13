//
// Array+Common.swift
//

import Foundation

extension Array {
    
    // MARK: -
    
    subscript(safe index: Int) -> Element? {
        return 0 <= index && index < count ? self[index] : nil
    }
}
