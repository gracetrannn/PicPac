//
//  FBXsheetCompositeCache.swift
//  FlipPad
//
//  Created by zuzex on 19.10.2021.
//  Copyright © 2021 Alex. All rights reserved.
//

import Foundation

class FBXsheetCompositeCache {
    
    private var cache = [Int: UIImage]()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(purgeAllCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc func purgeAllCache() {
        cache = [:]
    }
    
    func updateCacheFor(rows: IndexSet) {
        guard cache.count > (2 * 8) else {
            return // No reason for clearing
        }
        
        var clearedCache = [Int: UIImage]()
        for row in rows {
            let key = cacheKey(row: row)
            if let cachedComposite = cache[key] {
                clearedCache[key] = cachedComposite
            }
        }
        cache = clearedCache
    }
    
    private func cacheKey(row: Int) -> Int {
        return row
    }
    
    func fetchCompositeFromCacheAt(row: Int) -> UIImage? {
        return cache[cacheKey(row: row)]
    }
    
    func cacheComposite(_ composite: UIImage?, row: Int) {
        cache[cacheKey(row: row)] = composite
    }
    
    func shiftCompositesForwardStarting(fromRow row: Int) {
        var modifiedCache = [Int: UIImage]()
        for cachedPair in cache {
            var newRow = cachedPair.key
            
            if newRow == row {
//                modifiedCache[cacheKey(row: newRow)] = nil
            }
            
            if newRow >= row {
                newRow += 1
            }
            
            modifiedCache[cacheKey(row: newRow)] = cachedPair.value
        }
        cache = modifiedCache
    }
    
    func shiftCompositesBackwardStarting(fromRow row: Int) {
        var modifiedCache = [Int: UIImage]()
        for cachedPair in cache {
            var newRow = cachedPair.key
            
            if newRow == row {
                continue
            }
            
            if newRow > row {
                newRow -= 1
            }
            
            modifiedCache[cacheKey(row: newRow)] = cachedPair.value
        }
        cache = modifiedCache
    }
    
    func delete(row: Int) {
        if cache.index(forKey: cacheKey(row: row)) != nil {
            cache.removeValue(forKey: cacheKey(row: row))
        }
//        cache[cacheKey(row: row)] = nil
    }
    
}
