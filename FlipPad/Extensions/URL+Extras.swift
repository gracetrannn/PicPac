//
//  URL+Extras.swift
//  FlipPad
//
//  Created by Alex on 23.01.2020.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import Foundation

extension URL {
    
    static var iCloudDriveDocuments: URL? {
        return ns_cast(NSURL.iCloudDriveDocumentsFolder())
    }
    
    static var localDocStorage: URL? {
        return ns_cast(NSURL.localDocStorage())
    }

    static var iCloudDocStorage: URL? {
        return ns_cast(NSURL.iCloudDocStorage())
    }
    
    static var documents: URL? {
        return ns_cast(NSURL.documentsFolder())
    }
    
}

fileprivate func ns_cast(_ ns: NSURL!) -> URL? {
    let optional: NSURL? = ns as NSURL?
    return optional as URL?
}
