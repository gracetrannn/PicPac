//
// PurchasesRouter.swift
//

import UIKit

@objc class PurchasesRouter: NSObject,
                             PurchasesInputRouterProtocol {
    
    // MARK: - PurchasesRouterProtocol
    
    @objc weak var viewController: UIViewController?
    
    // MARK: - Static functions
    
    @objc static func create() -> PurchasesRouter {
        let view = PurchasesView.instantiate()
        let interactor = PurchasesInteractor()
        let presenter = PurchasesPresenter()
        let router = PurchasesRouter()
        view.presenter = presenter
        interactor.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        router.viewController = view
        return router
    }
    
    // MARK: - PurchasesInputRouterProtocol
    
    func dismiss(animated: Bool) {
        viewController?.dismiss(animated: animated)
    }
    
    func openBrowser(with url: URL) {
        let application = UIApplication.shared
        if application.canOpenURL(url) {
            application.open(url)
        }
    }
}
