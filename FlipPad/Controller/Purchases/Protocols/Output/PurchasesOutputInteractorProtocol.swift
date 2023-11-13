//
// PurchasesOutputInteractorProtocol.swift
//

import Foundation
import StoreKit

protocol PurchasesOutputInteractorProtocol: AnyObject {
    
    // MARK: -
    
    func didUpdateProducts(_ products: [Product])
    
    func didStartLoading()
    func didStopLoading()
    
    func didCompleteRestorePurchases()
    func didCompletePurchase()
    
    func didCatchError(_ error: Error)
}
