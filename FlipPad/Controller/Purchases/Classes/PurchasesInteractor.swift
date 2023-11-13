//
// PurchasesInteractor.swift
//

import Foundation

class PurchasesInteractor: PurchasesInputInteractorProtocol {
    
    // MARK: - PurchasesInteractorProtocol
    
    weak var presenter: PurchasesOutputInteractorProtocol?
    
    // MARK: - PurchasesInputInteractorProtocol
    
    var termsOfUseUrl: URL? {
        return URL(string: "https://digicel.net/eula")
    }
    
    var privacyPolicyUrl: URL? {
        return URL(string: "http://digicel.net/privacy/")
    }
    
    // MARK: -
    
    private var products = [
        Product(
            id: .liteId,
            icon: "lite_icon",
            name: "Lite",
            features: "- SD 480P\n- 300 Frames\n- 2 Levels\n- Unlimited Colors\n- 1 Audio File\n- Drag and Fill",
            price: "Loading...",
            isActive: false
        ),
        Product(
            id: .studioId,
            icon: "studio_icon",
            name: "Studio",
            features: "- HD 720P\n- 500 Frames\n- 6 Levels\n- Multiple Palettes\n- 2 Audio Files\n- Auto Advance",
            price: "Loading...",
            isActive: false
        ),
        Product(
            id: .proId,
            icon: "pro_icon",
            name: "Pro",
            features: "- Full HD 1080P\n- 1000 Frames\n- 100 Levels\n- Multiple Palettes\n- 3 Audio Files\n- Auto Fill Level",
            price: "Loading...",
            isActive: false
        )
    ]
    
    // MARK: -
    
    func start() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(didRestore(_:)), name: .didRestore, object: nil)
        center.addObserver(self, selector: #selector(didPurchase(_:)), name: .didPurchase, object: nil)
        center.addObserver(self, selector: #selector(didStartRefresh(_:)), name: .didStartRefresh, object: nil)
        center.addObserver(self, selector: #selector(didStopRefresh(_:)), name: .didStopRefresh, object: nil)
        presenter?.didUpdateProducts(products)
        fetchProducts()
    }
    
    func makeRestorePurchases() {
        presenter?.didStartLoading()
        IAPManager.restore()
    }
    
    func makePurchase(at index: Int) {
        guard let id = products[safe: index]?.id else {
            return
        }
        presenter?.didStartLoading()
        IAPManager.purchase(with: id)
    }
    
    // MARK: -
    
    private func fetchProducts() {
        presenter?.didStartLoading()
        IAPManager.fetchProducts(products.map { $0.id }) { [weak self] result in
            guard let self = self else {
                return
            }
            self.presenter?.didStopLoading()
            switch result {
            case .success(let skProducts):
                self.products = self.products.map { product in
                    var copy = product
                    copy.price = skProducts.first { skProduct in product.id == skProduct.productIdentifier }?.localizedPrice ?? copy.price
                    copy.isActive = FeatureManager.shared.isActive(with: product.id)
                    return copy
                }
                self.presenter?.didUpdateProducts(self.products)
            case .failure(let error):
                self.presenter?.didCatchError(error)
            }
        }
    }
    
    // MARK: -
    
    @objc private func didRestore(_ notification: Notification) {
        guard let error = notification.error else {
            return
        }
        presenter?.didStopLoading()
        presenter?.didCatchError(error)
    }
    
    @objc private func didPurchase(_ notification: Notification) {
        guard let error = notification.error else {
            return
        }
        presenter?.didStopLoading()
        presenter?.didCatchError(error)
    }
    
    @objc private func didStartRefresh(_ notification: Notification) {
        presenter?.didStartLoading()
    }
    
    @objc private func didStopRefresh(_ notification: Notification) {
        presenter?.didStopLoading()
        products = products.map {
            var copy = $0
            copy.isActive = FeatureManager.shared.isActive(with: copy.id)
            return copy
        }
        presenter?.didUpdateProducts(products)
    }
    
    // MARK: -
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
