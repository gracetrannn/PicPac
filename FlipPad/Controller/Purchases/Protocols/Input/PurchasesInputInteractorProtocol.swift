//
// PurchasesInputInteractorProtocol.swift
//

import Foundation

protocol PurchasesInputInteractorProtocol: AnyObject {
    
    // MARK: -
    
    var termsOfUseUrl: URL? { get }
    
    var privacyPolicyUrl: URL? { get }
    
    // MARK: -
    
    func start()
    
    func makeRestorePurchases()
    
    func makePurchase(at index: Int)
}
