//
// PurchasesInputRouterProtocol.swift
//

import Foundation

protocol PurchasesInputRouterProtocol: AnyObject {
    
    // MARK: -
    
    func dismiss(animated: Bool)
    
    func openBrowser(with url: URL)
}
