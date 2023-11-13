//
//  ProgressBarViewController.swift
//  FlipPad
//
//  Created by zuzex-62 on 26.01.2023.
//  Copyright © 2023 Alex. All rights reserved.
//

import UIKit

class ProgressBarViewController: UIViewController {
    
    @IBOutlet private weak var namelbl: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 300, height: 80)
    }

    @objc
    func setProgress(progress: Float) {
        progressView.progress = progress
    }
    
    @objc
    func setTitle(tile: String) {
        namelbl.text = title
    }
}
