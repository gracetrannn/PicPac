//
// PurchasesPresenter.swift
//

import Foundation

class PurchasesPresenter: PurchasesOutputViewProtocol,
                          PurchasesOutputInteractorProtocol {
    
    // MARK: - PurchasesPresenterProtocol
    
    weak var view: PurchasesInputViewProtocol?
    
    var interactor: PurchasesInputInteractorProtocol?
    
    var router: PurchasesInputRouterProtocol?
    
    // MARK: - PurchasesOutputViewProtocol
    
    func viewDidLoad() {
        interactor?.start()
    }
    
    func didTapClose() {
        router?.dismiss(animated: true)
    }
    
    func didTapRestorePurchases() {
        interactor?.makeRestorePurchases()
    }
    
    func didTapPurchase(at index: Int) {
        interactor?.makePurchase(at: index)
    }
    
    func didTapTermsOfUse() {
        guard let url = interactor?.termsOfUseUrl else {
            return
        }
        router?.openBrowser(with: url)
    }
    
    func didTapPrivacyPolicy() {
        guard let url = interactor?.privacyPolicyUrl else {
            return
        }
        router?.openBrowser(with: url)
    }
    
    // MARK: - PurchasesOutputInteractorProtocol
    
    func didUpdateProducts(_ products: [Product]) {
        view?.products = products
    }
    
    func didStartLoading() {
        Loader.show()
    }
    
    func didStopLoading() {
        Loader.hide()
    }
    
    func didCompleteRestorePurchases() {
        router?.dismiss(animated: true)
    }
    
    func didCompletePurchase() {
        router?.dismiss(animated: true)
    }
    
    func didCatchError(_ error: Error) {
        view?.showErrorAlert(with: error)
    }
}
