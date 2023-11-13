//
// PurchasesOutputViewProtocol.swift
//

import Foundation

protocol PurchasesOutputViewProtocol: AnyObject {
    
    
    // MARK: -
    
    func viewDidLoad()
    
    func didTapClose()
    
    func didTapRestorePurchases()
    
    func didTapPurchase(at index: Int)
    
    func didTapTermsOfUse()
    
    func didTapPrivacyPolicy()
}
