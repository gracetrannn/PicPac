//
// FeatureManager.swift
//

import Foundation
import SwiftyStoreKit
import SwiftKeychainWrapper
import UIKit

enum SubscriptionType: Int {
    
    case free = 0
    case lite = 1
    case studio = 2
    case pro = 3
    
    var name: String {
        switch self {
        case .lite: return "is_lite"
        case .studio: return "is_studio"
        case .pro: return "is_pro"
        case .free: return "is_free"
        }
    }
}

@objc class FeatureManager: NSObject {
    
    // MARK: -
    
    @objc static let shared = FeatureManager()
    
    // MARK: -
    
    public var activeSubscriptionType: SubscriptionType = .free
//    {
////        return isPro ? .pro : isStudio ? .studio : isLite ? .lite : .free
//        return .lite
//    }
    
    @objc private(set) var isLite: Bool
    @objc private(set) var isStudio: Bool
    @objc private(set) var isPro: Bool
    
    // MARK: -
    
    @objc var maxLevels: Int {
        
        var result = 1
        
        switch activeSubscriptionType {
        case .lite:     result = 2
        case .studio:   result = 6
        case .pro:      result = 100
        default:        result = 1
        }
        
        return result + 2 // 2 it's background and first foreground levels.
        
    }
    
    @objc var maxFrames: Int {
        
        switch activeSubscriptionType {
        case .free: return 100
        case .lite: return 300
        case .studio: return 500
        case .pro: return 1000
        }
    }
    
    @objc var maxResolution: Int {
        
        switch activeSubscriptionType {
        case .free, .lite: return 600
        case .studio: return 720
        case .pro: return 1080
        }
    }
    
    
    // MARK: -
    
    override init() {
        let wrapper = KeychainWrapper.standard
        
        self.isLite = wrapper.bool(forKey: SubscriptionType.lite.name) ?? false
        self.isStudio = wrapper.bool(forKey: SubscriptionType.studio.name) ?? false
        self.isPro = wrapper.bool(forKey: SubscriptionType.pro.name) ?? false
        print("Did fetch features access from keychain:", self.isLite, self.isStudio, self.isPro)

//        self.isLite = wrapper.bool(forKey: .isLite) ?? false
//        self.isStudio = wrapper.bool(forKey: .isStudio) ?? false
//        self.isPro = wrapper.bool(forKey: .isPro) ?? false
//        print("Did fetch features access from keychain:", self.isLite, self.isStudio, self.isPro)
        super.init()
    }
    
    // MARK: -
    
    func isActive(with id: String) -> Bool {
        switch id {
        case .liteId:
            return isLite
        case .studioId:
            return isStudio
        case .proId:
            return isPro
        default:
            return false
        }
    }
    
    func update(with receiptInfo: ReceiptInfo) {
        let liteResult = SwiftyStoreKit.verifySubscription(
            ofType: .autoRenewable,
            productId: .liteId,
            inReceipt: receiptInfo
        )
        let studioResult = SwiftyStoreKit.verifySubscription(
            ofType: .autoRenewable,
            productId: .studioId,
            inReceipt: receiptInfo
        )
        let proResult = SwiftyStoreKit.verifySubscription(
            ofType: .autoRenewable,
            productId: .proId,
            inReceipt: receiptInfo
        )
        switch liteResult {
        case .purchased:
            isLite = true
        case .expired, .notPurchased:
            isLite = false
        }
        switch studioResult {
        case .purchased:
            isStudio = true
        case .expired, .notPurchased:
            isStudio = false
        }
        switch proResult {
        case .purchased:
            isPro = true
        case .expired, .notPurchased:
            isPro = false
        }
        let wrapper = KeychainWrapper.standard
        wrapper.set(isLite, forKey: SubscriptionType.lite.name)
        wrapper.set(isStudio, forKey: SubscriptionType.studio.name)
        wrapper.set(isPro, forKey: SubscriptionType.pro.name)
        print("Did update features access:", isLite, isStudio, isPro)
    }
    
    // MARK: - Show Purchases Controller

    @objc func toPurchase (_ on: UIViewController) {
        
        guard let purchasesController = PurchasesRouter.create().viewController else { return }
        let purchasesNC = UINavigationController(rootViewController: purchasesController)
        purchasesNC.modalPresentationStyle = .pageSheet
        on.present(purchasesNC, animated: true)
        
    }
    
    func checkSubscribtion (_ type: SubscriptionType) -> Bool {
        return checkSubscribtion(type.rawValue)
    }
    
    @objc func checkSubscribtion (_ type: Int) -> Bool {
        return type <= activeSubscriptionType.rawValue
    }

}

private extension String {
    
    // MARK: -
    
//    static var isLite: String { "is_lite" }
//    static var isStudio: String { "is_studio" }
//    static var isPro: String { "is_pro" }
}
