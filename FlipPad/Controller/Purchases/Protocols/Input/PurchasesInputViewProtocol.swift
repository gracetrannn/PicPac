//
// PurchasesInputViewProtocol.swift
//

import Foundation

protocol PurchasesInputViewProtocol: UIAlertControllerProtocol {
    
    // MARK: -
    
    var products: [Product] { get set }
}
