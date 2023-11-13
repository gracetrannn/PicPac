//
// FBCellCache.swift
//

import Foundation

class FBCache<T>: CustomStringConvertible {
    
    // MARK: -
    
    private class FBCacheIndex<T>: CustomStringConvertible {
        
        // MARK: -
        
        var row: Int
        var column: Int
        
        var object: T
        
        // MARK: -
        
        var description: String {
            return "row: \(row), column: \(column), object: \(object)"
        }
        
        // MARK: -
        
        init(row: Int, column: Int, object: T) {
            self.row = row
            self.column = column
            self.object = object
        }
        
        // MARK: -
        
        func applyRow(with offset: Int) -> FBCacheIndex {
            row += offset
            return self
        }
        
        func applyColumn(with offset: Int) -> FBCacheIndex {
            column += offset
            return self
        }
    }
    
    // MARK: -
    
    private var cache: [FBCacheIndex<T>]
    
    var description: String {
        var result = ""
        for cacheIndex in cache {
            result += "\(cacheIndex)\n"
        }
        return result
    }
    
    // MARK: -
    
    init() {
        self.cache = []
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarningNotification(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: -
    
    @discardableResult
    func getObjectFrom(row: Int, column: Int) -> T? {
        return cache.first { $0.row == row && $0.column == column }?.object
    }
    
    func setObject(_ object: T?, row: Int, column: Int) {
        if let index = cache.firstIndex(where: { $0.row == row && $0.column == column }) {
            cache.remove(at: index)
        }
        if let object = object, !SettingsBundleHelper.editModeDevice {
             cache.append(FBCacheIndex<T>(row: row, column: column, object: object))
        }
    }
    
    // MARK: -
    
    func shiftDownFrom(row: Int, offset: Int = 1) {
        cache = cache.map { $0.row >= row ? $0.applyRow(with: offset) : $0 }
    }
    
    func shiftUpFrom(row: Int, offset: Int = 1) {
        cache = cache.map { $0.row >= row ? $0.applyRow(with: -offset) : $0 }
    }
    
    func shiftRightFrom(column: Int, offset: Int = 1) {
        cache = cache.map { $0.column >= column ? $0.applyColumn(with: -offset) : $0 }
    }
    
    func shiftLeftFrom(column: Int, offset: Int = 1) {
        cache = cache.map { $0.column >= column ? $0.applyColumn(with: offset) : $0 }
    }
    
    // MARK: -
    
    func removeObjectsWithRow(_ row: Int) {
        cache = cache.filter { $0.row != row }
    }
    
    func removeObjectsWithColumn(_ column: Int) {
        cache = cache.filter { $0.column != column }
    }
    
    // MARK: -
    
    func removeAll() {
        cache.removeAll()
    }
    
    // MARK: -
    
    @objc private func didReceiveMemoryWarningNotification(_ notification: Notification) {
        cache.removeAll()
    }
}
