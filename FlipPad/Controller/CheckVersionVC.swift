//
//  CheckVersionVC.swift
//  FlipPad
//
//  Created by Igor on 15.09.2022.
//  Copyright © 2022 Alex. All rights reserved.
//

import Foundation
import UIKit

class CheckVersionVC: UIViewController {
    
    private let titleLabel        = UILabel()
    private let descriptionLabel  = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private let retryButton       = UIButton()
    
    private let stackView         = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVC()
        self.checkTime()
    }
   
    private func setupVC() {
        self.view.backgroundColor = .lightGray
        self.view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis         = .vertical
        stackView.distribution = .fill
        stackView.alignment    = .fill
        stackView.spacing      = 16
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(retryButton)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0),
            stackView.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        // title setup
        
        titleLabel.textAlignment       = .center
        titleLabel.numberOfLines       = 0
        titleLabel.font                = .systemFont(ofSize: 25, weight: .bold)
        titleLabel.textColor           = .white
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font          = .systemFont(ofSize: 22, weight: .medium)
        descriptionLabel.textColor     = .white
        
        // button setup
        
        retryButton.isHidden = true
        retryButton.setTitle("Retry", for: .normal)
        retryButton.tintColor = .black
        retryButton.backgroundColor = .darkGray
        retryButton.layer.cornerRadius = 8
        retryButton.addTarget(self, action: #selector(pressRetryButton), for: .touchUpInside)
        retryButton.titleLabel?.font = .systemFont(ofSize: 25, weight: .bold)
        
        // activiry indicator setup
        
        activityIndicator.startAnimating()
    }
    
    @objc func pressRetryButton() {
        self.checkTime()
    }
    
    private func showLoadingState() {
        titleLabel.text       = "Checking version"
        descriptionLabel.text = "Please wait"
        
        retryButton.isHidden       = true
        activityIndicator.isHidden = false
    }
    
    private func showBadInternetConnectionState() {
        titleLabel.text       = "Error"
        descriptionLabel.text = "Please check internet connection and try again"
        
        retryButton.isHidden       = false
        activityIndicator.isHidden = true
    }
    
    private func showVersionNoLongerAvailableState() {
        titleLabel.text       = "Attention"
        descriptionLabel.text = "This beta version of FlipPad has expired. Please contact DigiCel for a new one."
        
        retryButton.isHidden       = true
        activityIndicator.isHidden = true
    }
    
    private func checkTime() {
        showLoadingState()
        let userDefaults = UserDefaults.standard
        let prevExpiredDate = userDefaults.double(forKey: "prevExpiredDate")
        let currentDate = Date()
        
        //.let interval = currentDate.timeIntervalSince1970 //.
        if prevExpiredDate == expireUnixDateOfApp {
            // Значит что приложение уже было заблокировано по этой дате (Нужно показать экран блокировки)
            showVersionNoLongerAvailableState()
        } else {
            // Приложение ещё не блокировалось по этой дате
            if currentDate.timeIntervalSince1970 > expireUnixDateOfApp {
                // Версия просрочилась (нужно дату сохранить и показать экран блокировки)
                userDefaults.set(expireUnixDateOfApp, forKey: "prevExpiredDate")
                showVersionNoLongerAvailableState()
            } else {
                // Версия актуальна (нужно продолжить открытие прложения)
                openDocumentsController()
            }
        }
        
//        TimeManager.shared.getTime { [weak self] currentUnixTime in
//            DispatchQueue.main.async {
//                if currentUnixTime != nil {
//                    if currentUnixTime! > expireUnixDateOfApp {
//                        self?.showVersionNoLongerAvailableState()
//                    } else {
//                        self?.openDocumentsController()
//                    }
//                } else {
//                    self?.showBadInternetConnectionState()
//                }
//            }
//        }
    }
    
    private func openDocumentsController() {
        if #available(iOS 13.0, *) {
            if let documentSceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? DocumentsSceneDelegate,
               let window = documentSceneDelegate.window,
               let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let docController = appDelegate.docsController {
                MenuAssembler.state = .edit
                window.rootViewController = docController
            }
        } else {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
               let window = appDelegate.window,
               let docController = appDelegate.docsController {
                window.rootViewController = docController
            }
        }
    }
}

