//
// FBPreviewCache.swift
//

import Foundation

@objc class FBPreviewCache: NSObject {
    
    // MARK: -
    
    private let cache: FBCache<FBImage>
    
    // MARK: -
    
    override init() {
        self.cache = FBCache<FBImage>()
        super.init()
        
    }
    
    // MARK: -
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: -
    
    @objc func getPreviewImageWithRow(_ row: Int, item: Int) -> FBImage? {
        return cache.getObjectFrom(row: row, column: item)
    }
    
    @objc func setPreviewImage(_ image: FBImage?, withRow row: Int, item: Int) {
        cache.setObject(image, row: row, column: item)
    }
    
    @objc func removePreviewImageWithRow(_ row: Int, item: Int) {
        cache.setObject(nil, row: row, column: item)
    }
    
    // MARK: -
    
    @objc func removeAll() {
        cache.removeAll()
    }
}
