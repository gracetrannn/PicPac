//
//  Constants.swift
//  FlipPad
//
//  Created by Alex on 06.12.2019.
//  Copyright © 2019 DigiCel, Inc. All rights reserved.
//

import Foundation

let kUsingNonDrawableGesturePrefKey = "UsingNonDrawableGesture"
let kUsingFillToolPrefKey = "UsingFillTool"

#if FLIPBOOK
let kPhotosAlbumName = "FlipBook";
#else
let kPhotosAlbumName = "FlipPad";
#endif

let kDCFB = "dcfb";
let kDGC = "dgc";

//.let expireUnixDateOfApp: TimeInterval = 1680220800 // 31 March 2023 00:00:00 GMT
let expireUnixDateOfApp: TimeInterval =    1703987000 // 31 March 2023 00:00:00 GMT
//                   _time    Double    721529261.07591605 13 Nov 2023


extension String {
    
    // MARK: -
    
    static var liteId: String { "com.digicelinc.flippad.subscriptions.lite" }
    static var studioId: String { "com.digicelinc.flippad.subscriptions.studio" }
    static var proId: String { "com.digicelinc.flippad.subscriptions.pro" }
}
