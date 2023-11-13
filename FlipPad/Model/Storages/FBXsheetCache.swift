//
//  FBXsheetCache.swift
//  FlipPad
//
//  Created by Alex on 11.07.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import Foundation

class FBXsheetCache {
    
    private var cache = [String: FBCachedCell]()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(purgeAllCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc func purgeAllCache() {
        cache = [:]
    }
    
    func updateCacheFor(rows: IndexSet, columnsCount: Int) {
        guard cache.count > (2 * 8) else {
            return // No reason for clearing
        }
        
        var clearedCache = [String: FBCachedCell]()
        for row in rows {
            for column in 1...columnsCount {
                let key = cacheKey(row: row, column: column)
                if let cachedCell = cache[key] {
                    clearedCache[key] = cachedCell
                }
            }
        }
        cache = clearedCache
    }
    
    private func cacheKey(row: Int, column: Int) -> String {
        return "\(row);\(column)"
    }
    
    func fetchCellFromCacheAt(row: Int, column: Int) -> FBCachedCell? {
        return cache[cacheKey(row: row, column: column)]
    }
    
    func cacheCell(_ cell: FBCachedCell) {
        cache[cacheKey(row: cell.row, column: cell.column)] = cell
    }
    
    func shiftCellsForwardStarting(fromRow row: Int) {
        var modifiedCache = [String: FBCachedCell]()
        for cachedPair in cache {
            var newRow = cachedPair.value.row
            
            if newRow == row {
//                modifiedCache[cacheKey(row: newRow, column: cachedPair.value.column)] = nil
            }
            
            if newRow >= row {
                newRow += 1
                cachedPair.value.row = newRow
            }
            modifiedCache[cacheKey(row: newRow, column: cachedPair.value.column)] = cachedPair.value
        }
        cache = modifiedCache
    }
    
    func shiftCellsBackwardStarting(fromRow row: Int) {
        var modifiedCache = [String: FBCachedCell]()
        for cachedPair in cache {
            var newRow = cachedPair.value.row
            
            if newRow == row {
                continue
            }
            
            if newRow > row {
                newRow -= 1
                cachedPair.value.row = newRow
            }
            
            modifiedCache[cacheKey(row: newRow, column: cachedPair.value.column)] = cachedPair.value
        }
        cache = modifiedCache
    }
    
    func shiftCellsForwardStarting(fromColumn column: Int) {
        var modifiedCache = [String: FBCachedCell]()
        for cachedPair in cache {
            var newColumn = cachedPair.value.column
            
            if newColumn == column {
//                modifiedCache[cacheKey(row: cachedPair.value.column, column: newColumn)] = nil
            }
            
            if newColumn >= column {
                newColumn += 1
                cachedPair.value.column = newColumn
            }
            modifiedCache[cacheKey(row: cachedPair.value.row, column: newColumn)] = cachedPair.value
        }
        cache = modifiedCache
    }
    
    func shiftCellsBackwardStarting(fromColumn column: Int) {
        var modifiedCache = [String: FBCachedCell]()
        for cachedPair in cache {
            var newColumn = cachedPair.value.column

            if newColumn == column {
                continue
            }

            if newColumn > column {
                newColumn -= 1
                cachedPair.value.column = newColumn
            }

            modifiedCache[cacheKey(row: cachedPair.value.row, column: newColumn)] = cachedPair.value
        }
        cache = modifiedCache
    }
    
    func delete(row: Int, column: Int) {
        if cache.index(forKey: cacheKey(row: row, column: column)) != nil {
            cache.removeValue(forKey: cacheKey(row: row, column: column))
        }
//        cache[cacheKey(row: row, column: column)] = nil
    }
    
}
