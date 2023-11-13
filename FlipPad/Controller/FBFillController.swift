//
//  FBFillController.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 1/22/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

enum ModeChecked {
    case normal
    case autoAdvance
    case dragAndFill
}

@objc protocol FBFillControllerDelegate: AnyObject {
    
    func didChangeFillMode(to mode: FBFillMode)
    
    func didApplyAutoFillMode()
}

class FBFillController: UIViewController {
    
    // MARK: -
    
    @IBOutlet private weak var normalButton: RadioButton!
    @IBOutlet private weak var autoAdvanceButton: RadioButton!
    @IBOutlet private weak var dragAndFillButton: RadioButton!
    
    @IBOutlet private weak var autoFillLevelButton: UIButton!
    
    @IBOutlet private weak var useThresholdButton: UIButton!
    
    @IBOutlet private weak var thresholdLabel: UILabel!
    
    @IBOutlet private weak var thresholdSlider: UISlider!
    
    @IBOutlet private weak var closeButtonView: UIView!
    
    // MARK: -
    
    @objc weak var delegate: FBFillControllerDelegate?
    
    // MARK: -
    
    private var modeChacked: ModeChecked = .normal {
    willSet {
            self.setChecked(newValue)
        }
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom != .phone {
            closeButtonView.isHidden = true
        }
        
        self.preferredContentSize = self.view.bounds.size
        self.popoverPresentationController?.delegate = self
        self.normalButton.isReversingOnState = false
        self.autoAdvanceButton.isReversingOnState = false
        self.dragAndFillButton.isReversingOnState = false
        /*
         self.autoFillLevelButton.isReversingOnState = false
         */
        self.modeChacked = .normal
        
        autoFillLevelButton.setImage(UIImage(named: "toolbar_fill_off")?.withRenderingMode(.alwaysTemplate), for: .normal)
        let threshold = Float(SettingsBundleHelper._threshold)
        let useThreshold = SettingsBundleHelper.useThreshold
        let value = threshold / 255.0
        useThresholdButton.isSelected = useThreshold
        thresholdSlider.value = value
        update()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.autoAdvanceButton.alpha = FeatureManager.shared.checkSubscribtion(.studio) ? 1 : 0.5
        self.autoFillLevelButton.alpha = FeatureManager.shared.checkSubscribtion(.pro)  ? 1 : 0.5
    }
    
    private func update() {
        let value = 100.0 * thresholdSlider.value
        thresholdLabel.text = String(format: "%0.2f%%", value)
    }
    
    
    // MARK: -
    
    @IBAction func normalChecked() {
        self.setChecked(.normal)
        delegate?.didChangeFillMode(to: .normal)
    }
    
    @IBAction func autoAdvanceChecked() {
        
        guard FeatureManager.shared.checkSubscribtion(.studio) else {
            self.autoAdvanceButton.isChecked = false

            self.dismiss(animated: false) { [weak self] in
                let vc = self?.delegate as? UIViewController ?? UIViewController()
                UIAlertController.showBlockedAlertController(for: vc, feature: "AutoAdvance fill", level: "Studio")
            }
            return
        }
        
        self.setChecked(.autoAdvance)
        delegate?.didChangeFillMode(to: .autoAdvance)
    }
    
    @IBAction func autoFillChecked() {
        
        guard FeatureManager.shared.checkSubscribtion(.pro) else {
            
            self.dismiss(animated: false) { [weak self] in
                let vc = self?.delegate as? UIViewController ?? UIViewController()
                UIAlertController.showBlockedAlertController(for: vc, feature: "AutoFill Level", level: "Pro")
            }
            return
        }
        
        self.setChecked(.normal)
        self.dismiss(animated: true) { [weak self] in
            self?.delegate?.didApplyAutoFillMode()
        }
    }
    
    @IBAction func dragAndFillChecked(_ sender: Any) {
        self.setChecked(.dragAndFill)

        delegate?.didChangeFillMode(to: .dragAndFill)
    }
    
    private func setChecked(_ mode: ModeChecked) {
        uncheckAll()
        
        switch mode {
        case .normal:
            normalButton.isChecked = true
        case .autoAdvance:
            autoAdvanceButton.isChecked = true
        case .dragAndFill:
            dragAndFillButton.isChecked = true
        }
    }
    
    private func uncheckAll() {
        [normalButton, autoAdvanceButton, dragAndFillButton]
            .forEach({ $0?.isChecked = false })
    }
    
    
    @IBAction private func useThresholdButtonHandler(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        thresholdSlider.isEnabled = sender.isSelected
        SettingsBundleHelper.useThreshold = sender.isSelected
    }
    
    @IBAction private func thresholdSliderHandler(_ sender: UISlider) {
        update()
        SettingsBundleHelper._threshold = Int(255.0 * sender.value)
    }
    
    @IBAction private func pressCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}

extension FBFillController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
