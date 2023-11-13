//
// String+Common.swift
//

import Foundation

public extension String {
    
    // MARK: -
    
    static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }
    
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
    
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: -
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
