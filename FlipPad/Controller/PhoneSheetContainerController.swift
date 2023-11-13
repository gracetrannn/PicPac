//
//  PhoneSheetContainerController.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 4/13/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

class PhoneSheetContainerController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    
    @objc var containedController: UIViewController? {
        didSet {
            if let containedController = containedController {
                addChild(containedController)
                //
                let view = containedController.view!
                view.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(view)
                view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
                view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
                view.leftAnchor.constraint(equalTo: self.contentView.leftAnchor).isActive = true
                view.rightAnchor.constraint(equalTo: self.contentView.rightAnchor).isActive = true
                //
                view.widthAnchor.constraint(equalToConstant: containedController.preferredContentSize.width).isActive = true
                view.heightAnchor.constraint(equalToConstant: containedController.preferredContentSize.height).isActive = true
                //
                containedController.didMove(toParent: self)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 8.0        
    }

    @IBAction func closeSheet() {
        dismiss(animated: true, completion: nil)
    }
    
}
