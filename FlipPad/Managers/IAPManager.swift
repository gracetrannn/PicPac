//
//  IAPManager.swift
//

import StoreKit
import SwiftyStoreKit
import Reachability

// MARK: -

extension Notification.Name {
    
    static var didPurchase: Self { Notification.Name("didPurchase") }
    static var didRestore: Self { Notification.Name("didRestore") }
    static var didStartRefresh: Self { Notification.Name("didStartRefresh") }
    static var didStopRefresh: Self { Notification.Name("didStopRefresh") }
}

// MARK: -

extension Notification {
    
    var error: Error? { userInfo?["error"] as? Error }
}

// MARK: -

extension Error {
    
    var getUserInfo: [String : Any] { ["error" : self] }
}

// MARK: -

class IAPManager {
    
    // MARK: -
    
    static private var center: NotificationCenter { NotificationCenter.default }
    
    static private var reachability = try? Reachability()
    
    static private var isFirstReachable = true
    
    static var sharedSecret = ""
    
    static private var defaultService: AppleReceiptValidator.VerifyReceiptURLType {
#if DEBUG
        return .sandbox
#else
        return .production
#endif
    }
    
    static private var service = defaultService
    
    // MARK: -
    
    static func setup() {
        reachability?.whenReachable = { _ in
            refresh()
        }
        try? reachability?.startNotifier()
        SwiftyStoreKit.completeTransactions { purchases in
            purchases.forEach {
                switch $0.transaction.transactionState {
                case .purchased, .restored:
                    if $0.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction($0.transaction)
                    }
                default:
                    break
                }
            }
            refresh()
        }
    }
    
    static func fetchProducts(_ products: [String], _ complition: @escaping (Result<Set<SKProduct>, Error>) -> Void) {
        SwiftyStoreKit.retrieveProductsInfo(Set(products)) { results in
            DispatchQueue.main.async {
                if let error = results.error {
                    print("[IAPManager] \(#function): \(error)")
                    complition(.failure(error))
                    return
                }
                print("[IAPManager] \(#function): \(results.retrievedProducts)")
                complition(.success(results.retrievedProducts))
            }
        }
    }
    
    static func purchase(with productIdentifier: String) {
        SwiftyStoreKit.purchaseProduct(productIdentifier) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let product):
                    print("[IAPManager] \(#function): \(product)")
                    refresh()
                case .error(let error):
                    if error.code == .paymentCancelled {
                        center.post(name: .didPurchase, object: nil)
                        return
                    }
                    print("[IAPManager] \(#function): \(error)")
                    center.post(name: .didPurchase, object: nil, userInfo: error.getUserInfo)
                case .deferred(let purchase):
                    // TODO: -
                    print("[IAPManager] \(#function): \(purchase)")
                }
            }
        }
    }
    
    static func restore() {
        SwiftyStoreKit.restorePurchases { result in
            DispatchQueue.main.async {
                result.restoredPurchases.forEach { print("[IAPManager] \(#function) \($0)") }
                result.restoreFailedPurchases.forEach { print("[IAPManager] \(#function): \($0.0) \(String(describing: $0.1))") }
                if !result.restoredPurchases.isEmpty {
                    refresh()
                    return
                }
                let userInfo = [
                    NSLocalizedDescriptionKey : "Can't restore purchases".localized
                ]
                let error = NSError(domain: "IAPManagerErrorDomain", code: 0, userInfo: userInfo)
                center.post(name: .didRestore, object: nil, userInfo: error.getUserInfo)
            }
        }
    }
    
    // MARK: -
    
    static private func refresh() {
        center.post(name: .didStartRefresh, object: nil)
        let validator = AppleReceiptValidator(
            service: service,
            sharedSecret: sharedSecret
        )
        SwiftyStoreKit.verifyReceipt(using: validator) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let receipt):
                    print("[IAPManager] \(#function): \(receipt)")
                    DispatchQueue.main.async {
                        FeatureManager.shared.update(with: receipt)
                        center.post(name: .didStopRefresh, object: nil, userInfo: ["receipt": receipt])
                    }
                case .error(let error):
                    if service == .production {
                        service = .sandbox
                        refresh()
                        return
                    }
                    print("[IAPManager] \(#function): \(error)")
                    DispatchQueue.main.async {
                        center.post(name: .didStopRefresh, object: nil)
                    }
                }
                service = defaultService
            }
        }
    }
}
