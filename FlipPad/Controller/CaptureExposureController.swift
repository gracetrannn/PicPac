//
//  CaptureExposureController.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 9/12/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

let kCaptureWhiteKey: String = "captureWhiteKey"
let kCaptureGammaKey: String = "captureGammaKey"

@objc protocol CaptureExposureControllerDelegate: AnyObject {
    
    func didChangeWhite(value: Float)
    
    func didChangeGamma(value: Float)
    
}

class CaptureExposureController: UIViewController {

    @IBOutlet weak var whiteLabel: UILabel!
    @IBOutlet weak var whiteSlider: UISlider!
    
    @IBOutlet weak var gammaLabel: UILabel!
    @IBOutlet weak var gammaSlider: UISlider!
    
    @objc weak var delegate: CaptureExposureControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        whiteSlider.setValue((UserDefaults.standard.value(forKey: kCaptureWhiteKey) as? Float) ?? 50.0, animated: false)
        gammaSlider.setValue((UserDefaults.standard.value(forKey: kCaptureGammaKey) as? Float) ?? 50.0, animated: false)
    }
    
    @IBAction func whiteValueChanged(_ sender: UISlider) {
        whiteLabel.text = String(Int(sender.value))
        delegate?.didChangeWhite(value: sender.value)
        UserDefaults.standard.set(sender.value, forKey: kCaptureWhiteKey)
    }
    
    @IBAction func gammaValueChanged(_ sender: UISlider) {
        gammaLabel.text = String(Int(sender.value))
        delegate?.didChangeGamma(value: sender.value)
        UserDefaults.standard.set(sender.value, forKey: kCaptureGammaKey)
    }
    
}
