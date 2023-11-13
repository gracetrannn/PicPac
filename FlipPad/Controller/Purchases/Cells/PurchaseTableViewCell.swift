//
// PurchaseTableViewCell.swift
//

import UIKit

protocol PurchaseTableViewCellDelegate: AnyObject {
    
    // MARK: -
    
    func purchaseTableViewCellDidTapPurchase(_ purchaseTableViewCell: PurchaseTableViewCell)
}

class PurchaseTableViewCell: UITableViewCell {
    
    // MARK: -
    
    @IBOutlet private weak var iconImageView: UIImageView!
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var activeLabel: UILabel!
    @IBOutlet private weak var featuresLabel: UILabel!
    
    @IBOutlet private weak var purchaseButton: UIButton!
    
    // MARK: -
    
    weak var delegate: PurchaseTableViewCellDelegate?
    
    var icon: UIImage? {
        get {
            return iconImageView.image
        }
        set {
            iconImageView.image = newValue
        }
    }
    
    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }
    
    var features: String? {
        get {
            return featuresLabel.text
        }
        set {
            featuresLabel.text = newValue
        }
    }
    
    var price: String? {
        get {
            return purchaseButton.title(for: .normal)
        }
        set {
            purchaseButton.setTitle(newValue, for: .normal)
        }
    }
    
    var isActive: Bool {
        get {
            return !activeLabel.isHidden
        }
        set {
            activeLabel.isHidden = !newValue
        }
    }
    
    // MARK: -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        purchaseButton.layer.cornerRadius = 8.0
        purchaseButton.layer.masksToBounds = true
    }
    
    // MARK: -
    
    @IBAction private func purchaseButtonAction(_ sender: UIButton) {
        delegate?.purchaseTableViewCellDidTapPurchase(self)
    }
}
