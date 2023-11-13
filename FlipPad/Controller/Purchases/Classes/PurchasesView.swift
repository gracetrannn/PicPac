//
// PurchasesView.swift
//

import UIKit

class PurchasesView: UIViewController,
                     PurchasesInputViewProtocol,
                     UITableViewDataSource,
                     PurchaseTableViewCellDelegate {
    
    // MARK: -
    
    @IBOutlet private weak var tableView: UITableView!
    
    @IBOutlet private weak var termsOfUseButton: UIButton!
    @IBOutlet private weak var privacyPolicyButton: UIButton!
    
    // MARK: -
    
    var presenter: PurchasesOutputViewProtocol?
    
    // MARK: - PurchasesInputViewProtocol
    
    var products = [Product]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Purchases".localized
        let closeBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(closeBarButtonItemAction(_:))
        )
        let restorePurchasesBarButtonItem = UIBarButtonItem(
            title: "Restore",
            style: .plain,
            target: self,
            action: #selector(restorePurchasesBarButtonItemAction(_:))
        )
        navigationItem.leftBarButtonItem = closeBarButtonItem
        navigationItem.rightBarButtonItem = restorePurchasesBarButtonItem
        for button in [termsOfUseButton, privacyPolicyButton] {
            button?.layer.cornerRadius = 8.0
            button?.layer.masksToBounds = true
        }
        presenter?.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "PurchasesHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "PurchasesHeaderView")

    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: PurchaseTableViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PurchaseTableViewCell
        if let product = products[safe: indexPath.row] {
            cell.delegate = self
            cell.icon = UIImage(named: product.icon ?? "")
            cell.name = product.name
            cell.features = product.features
            cell.price = product.price
            cell.isActive = product.isActive
        }
        return cell
    }
    
    // MARK: - PurchaseTableViewCellDelegate
    
    func purchaseTableViewCellDidTapPurchase(_ purchaseTableViewCell: PurchaseTableViewCell) {
        guard let row = tableView.indexPath(for: purchaseTableViewCell)?.row else {
            return
        }
        
//        FeatureManager.shared.activeSubscriptionType = SubscriptionType(rawValue: row + 1) ?? .free
//
//        let alert = UIAlertController(title: "Purchased!", message: "Current level: \(FeatureManager.shared.activeSubscriptionType.name)", preferredStyle: .alert)
//        alert.addAction(.init(title: "OK", style: .cancel))
//        present(alert, animated: true)
        
        // TODO: UNCOMMENT THIS BEFORE RELEASE!

        presenter?.didTapPurchase(at: row)
    }
    
    // MARK: -
    
    @objc private func closeBarButtonItemAction(_ sender: UIBarButtonItem) {
        presenter?.didTapClose()
    }
    
    @objc private func restorePurchasesBarButtonItemAction(_ sender: UIBarButtonItem) {
        presenter?.didTapRestorePurchases()
    }
    
    // MARK: -
    
    @IBAction private func termsOfUseButtonAction(_ sender: UIButton) {
        
//        FeatureManager.shared.activeSubscriptionType = .free
//
//        let alert = UIAlertController(title: "Purchased!", message: "Current level: \(FeatureManager.shared.activeSubscriptionType.name)", preferredStyle: .alert)
//        alert.addAction(.init(title: "OK", style: .cancel))
//        present(alert, animated: true)

        // TODO: UNCOMMENT THIS BEFORE RELEASE!

        presenter?.didTapTermsOfUse()
    }
    
    @IBAction private func privacyPolicyButtonAction(_ sender: UIButton) {
        
        // TODO: UNCOMMENT THIS BEFORE RELEASE!
        //fatalError("TEST ERROR!")
        presenter?.didTapPrivacyPolicy()
    }
}

extension PurchasesView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "PurchasesHeaderView") as? PurchasesHeaderView
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}
