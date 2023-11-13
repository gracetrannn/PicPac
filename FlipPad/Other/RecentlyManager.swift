//
// RecentlyManager.swift
//

import UIKit

@objc public class RecentlyManager: NSObject {
    
    // MARK: -
    
    @objc static public let shared = RecentlyManager()
    
    // MARK: -
    
    @objc public var max = 5
    
    // MARK: -
    
    @objc public func recentlyPaths() -> [String] {
        return UserDefaults.standard.object(forKey: .recentlyPathsKey) as? [String] ?? []
    }
    
    @objc public func addRecentlyPath(_ recentlyPath: String) {
        var recentlyPaths = recentlyPaths()
        if let index = recentlyPaths.firstIndex(of: recentlyPath) {
            recentlyPaths.remove(at: index)
        }
        if recentlyPaths.count > max {
            recentlyPaths.removeLast()
        }
        recentlyPaths.insert(recentlyPath, at: 0)
        UserDefaults.standard.set(recentlyPaths, forKey: .recentlyPathsKey)
    }
    
    @objc public func clear() {
        UserDefaults.standard.set([], forKey: .recentlyPathsKey)
    }
}

private extension String {
    
    // MARK: -
    
    static var recentlyPathsKey: String {
        return "recentlyPaths"
    }
}
