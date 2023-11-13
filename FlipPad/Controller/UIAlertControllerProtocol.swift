//
// UIAlertControllerProtocol.swift
//

import UIKit

protocol UIAlertControllerProtocol: UIViewController {
    
    // MARK: -
    
    func showErrorAlert(with error: Error)
    
    func showErrorAlert(with message: String)
    
    func showEditAlert(
        title: String?,
        message: String?,
        text: String?,
        placeholder: String?,
        block: @escaping (String) -> Void
    )
    
    func showDeleteAlert(
        title: String?,
        message: String?,
        block: @escaping () -> Void
    )
}

extension UIViewController {
    
    // MARK: -
    
    func showErrorAlert(with error: Error) {
        UIAlertController.showError(with: error, for: self)
    }
    
    func showErrorAlert(with message: String) {
        UIAlertController.showError(with: message, for: self)
    }
    
    func showEditAlert(
        title: String?,
        message: String?,
        text: String?,
        placeholder: String?,
        block: @escaping (String) -> Void
    ) {
        UIAlertController.showEdit(
            title: title,
            message: message,
            text: text,
            placeholder: placeholder,
            for: self,
            block: block
        )
    }
    
    func showDeleteAlert(
        title: String?,
        message: String?,
        block: @escaping () -> Void
    ) {
        UIAlertController.showDelete(
            title: title,
            message: message,
            for: self,
            block: block
        )
    }
}
