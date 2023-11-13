//
//  SettingsBundleHelper.swift
//  FlipPad
//
//  Created by Alex on 28.01.2020.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import Foundation

@objc enum StorageType: Int {
    case local = 0, iCloud
}

@objc enum XSheetLocation: Int {
    case leading = 0, trailing
}

@objc class SettingsBundleHelper: NSObject {
    
    struct SettingsBundleKeys {
        static let iCloudBackups             = "iCloudBackups"
        static let storageType               = "storageType"
        static let xsheetLocation            = "xsheetLocation"
        static let xsheetIsClosed            = "xsheetIsClosed"
        static let verticalToolbar           = "verticalToolbar"
        static let cutOrCopyMode             = "cutOrCopyRequestedWithPath"
        static let resolutionsCheat          = "resolutionsCheat"
//        static let xsheetAlwaysVisible       = "xsheetAlwaysVisible"
        static let instrumentToolBarPosition = "instrumentToolBarPosition"
        static let navigationToolBarPosition = "navigationToolBarPosition"
        static let playBackToolBarPosition   = "playBackToolBarPosition"
        
        static let brushCircleViewPoint = "brushCircleViewPoint"
    }
    
    @objc static var useThreshold: Bool {
        get {
            return UserDefaults.standard.bool(forKey: kUseThreshold)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kUseThreshold)
        }
    }
    
    @objc static var _threshold: Int {
        get {
            return UserDefaults.standard.integer(forKey: kThreshold)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kThreshold)
        }
    }
    
    @objc static var threshold: Int {
        return useThreshold ? (_threshold > 254 ? 254 : _threshold) : 0
    }
    
    @objc class var iCloudBackupsEnabled: Bool {
        return UserDefaults.standard.bool(forKey: SettingsBundleKeys.iCloudBackups)
    }
    
    @objc class var storageType: StorageType {
        return StorageType(rawValue: UserDefaults.standard.integer(forKey: SettingsBundleKeys.storageType)) ?? StorageType.local
    }
    
    @objc class var xsheetLocation: XSheetLocation {
        get {
            return XSheetLocation(rawValue: UserDefaults.standard.integer(forKey: SettingsBundleKeys.xsheetLocation)) ?? XSheetLocation.leading
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: SettingsBundleKeys.xsheetLocation)
        }
    }
    
    @objc class var xsheetIsClosed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsBundleKeys.xsheetIsClosed)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsBundleKeys.xsheetIsClosed)
        }
    }
    
    @objc class var verticalToolbar: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsBundleKeys.verticalToolbar)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsBundleKeys.verticalToolbar)
        }
    }
    
    @objc class var editModeDevice: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsBundleKeys.cutOrCopyMode)
        }
        set {
            #if !TARGET_OS_MACCATALYST
            UserDefaults.standard.set(newValue, forKey: SettingsBundleKeys.cutOrCopyMode)
            #endif
        }
    }
    
    @objc class var resolutionsCheatVisible: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsBundleKeys.resolutionsCheat)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsBundleKeys.resolutionsCheat)
        }
    }
    
    @objc class var xsheetRightSide: Bool {
        get {
            return xsheetLocation == .trailing
        }
        set {
            xsheetLocation = newValue ? .trailing : .leading
        }
    }
    
//    @objc class var xsheetAlwaysVisible: Bool {
//        get {
//            return UserDefaults.standard.bool(forKey: SettingsBundleKeys.xsheetAlwaysVisible)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: SettingsBundleKeys.xsheetAlwaysVisible)
//        }
//    }
    
    @objc class var instrumentToolbarPosition: CGPoint {
        get {
            guard let pointData = UserDefaults.standard.data(forKey: SettingsBundleKeys.instrumentToolBarPosition) else {
                return .zero
            }
            return self.decodePosition(data: pointData)
        }
        set {
            guard let pointData = self.encodePosition(point: newValue) else {
                return
            }
            // FIXME: - need to think how to stop looping
            UserDefaults.standard.set(pointData, forKey: SettingsBundleKeys.instrumentToolBarPosition)
        }
    }
    
    @objc class var navigationToolbarPosition: CGPoint {
        get {
            guard let pointData = UserDefaults.standard.data(forKey: SettingsBundleKeys.navigationToolBarPosition) else {
                return CGPoint(x: -1000, y: -1000)
            }
            return self.decodePosition(data: pointData)
        }
        set {
            guard let pointData = self.encodePosition(point: newValue) else {
                return
            }
            // FIXME: - need to think how to stop looping
            UserDefaults.standard.set(pointData, forKey: SettingsBundleKeys.navigationToolBarPosition)
        }
    }
    
    @objc static var brushCircleViewPoint: CGPoint {
        get {
            let undefined = CGPoint(x: -1.0, y: -1.0)
            guard let data = UserDefaults.standard.data(forKey: SettingsBundleKeys.brushCircleViewPoint) else {
                return undefined
            }
            return (try? JSONDecoder().decode(CGPoint.self, from: data)) ?? undefined
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            // FIXME: - need to think how to stop looping
            UserDefaults.standard.set(data, forKey: SettingsBundleKeys.brushCircleViewPoint)
        }
    }
    
    @objc class var playBackToolBarPosition: CGPoint {
        get {
            guard let pointData = UserDefaults.standard.data(forKey: SettingsBundleKeys.playBackToolBarPosition) else {
                return CGPoint(x: -1000, y: -1000)
            }
            return self.decodePosition(data: pointData)
        }
        set {
            guard let pointData = self.encodePosition(point: newValue) else {
                return
            }
            // FIXME: - need to think how to stop looping
            UserDefaults.standard.set(pointData, forKey: SettingsBundleKeys.playBackToolBarPosition)
        }
    }
    
    
    @objc class private func encodePosition(point: CGPoint) -> Data? {
        let pointDict = ["point": point]
        return try? JSONEncoder().encode(pointDict)
        
    }
    
    @objc class private func decodePosition(data: Data) -> CGPoint {
        let pointDict = try? JSONDecoder().decode([String: CGPoint].self, from: data)
        return pointDict?["point"] ?? CGPoint(x: -1000, y: -1000)
     }
}
