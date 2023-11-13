//
//  XSheetHeaderView.swift
//  FlipPad
//
//  Created by Alex on 2/14/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import UIKit

@objc protocol XSheetHeaderViewDelegate: class {
    
    func didLongPressInLevelAt(index: Int, sourceView: UIView)
    
    func sheetHeaderViewDidClickEditButton(_ sheetHeaderView: XSheetHeaderView)
}

class XSheetHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var stackView: UIStackView!
    
    @objc weak var delegate: XSheetHeaderViewDelegate?
    
    private var headers: [FooterView] = []
    private let headerViewFrame = CGRect(x: 0, y: 0, width: 80, height: 30)
    
    @objc func headerOfColumn(at index: Int) -> UIView {
        let reversedHeaders = Array(headers.reversed())
        let header = reversedHeaders[index]
        return header
    }
    
    @objc func setup(_ framesCount: Int, levelNames: [String], isHiddenMap: [Bool]) {
        // Clear all
        headers.removeAll()
        stackView.subviews.forEach { $0.removeFromSuperview() }
        
        // Foregrounds
        for i in (1...framesCount-1).reversed() {
            let header = FooterView(frame: headerViewFrame)
            headers.append(header)
            stackView.addArrangedSubview(header)
            header.title = levelNames[i]
            header.isHidden = isHiddenMap[i]
            header.isCustomHidden = isHiddenMap[i]
        }
        // Background
        let backgroundHeader = FooterView(frame: headerViewFrame)
        backgroundHeader.title = levelNames[0]
        backgroundHeader.isHidden = isHiddenMap[0]
        backgroundHeader.isCustomHidden = isHiddenMap[0]
        
        headers.append(backgroundHeader)
        stackView.addArrangedSubview(backgroundHeader)
        
        // Setup long press actions
        for (index, header) in headers.reversed().enumerated() {
            header.tag = index
            header.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressed)))
        }
    }
    
    @objc func longPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else {
            return
        }
        delegate?.didLongPressInLevelAt(index: recognizer.view!.tag, sourceView: recognizer.view!)
    }
    
    @IBAction func editButtonAction(_ sender: UIButton) {
        delegate?.sheetHeaderViewDidClickEditButton(self)
    }
}
