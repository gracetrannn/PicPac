//
//  Cell.swift
//  draganddrop
//
//  Created by Alex on 2/11/20.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit

@objc protocol XSheetTableCellDelegate: AnyObject {
    
    func xSheetTableViewCellDidTap(_ xSheetTableViewCell: XSheetTableCell)
    func xSheetTableViewCell(_ xSheetTableViewCell: XSheetTableCell, didTapOnItem index: Int)
}

class XSheetTableCell: UITableViewCell {
    
    // MARK: -
    
    @IBOutlet weak var numberView: UIView!
    
    @IBOutlet weak var numberLabel: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var bottomLineView: UIView!
    
    @IBOutlet weak var placeholderView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: -
    
    @objc weak var delegate: XSheetTableCellDelegate?
    
    // MARK: -
    
    private var cells: [FrameView] {
        return stackView.arrangedSubviews as! [FrameView]
    }
    
    // MARK: -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = .zero
        selectionStyle = .none
        contentView.backgroundColor = .separatorColor
        bottomLineView.backgroundColor = .separatorColor
        numberLabel.textColor = .black
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.isHidden = true
        placeholderView.isHidden = false
        activityIndicator.startAnimating()
    }
    
    // MARK: -
    
    @objc
    public func configure(
        cells: [FBCell],
        isLockedMap: [Bool],
        isHiddenMap: [Bool],
        delegate: UIDragInteractionDelegate & UIDropInteractionDelegate
    ) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.gestureRecognizers?.forEach { stackView.removeGestureRecognizer($0) }
        numberView.gestureRecognizers?.forEach { numberView.removeGestureRecognizer($0) }
        let frame = CGRect(
            x: 0.0,
            y: 0.0,
            width: (stackView.frame.width - 1.0 * CGFloat(cells.count - 1)) / CGFloat(cells.count),
            height: 60.0
        )
        let count = cells.count
        for i in 0..<count {
            let cell = cells[i]
            let view = FrameView(frame: frame, cell: cell)
            view.tag = count - i
            view.type = cell.frameType
            view.isHidden = isHiddenMap[i]
            view.isLocked = isLockedMap[i]
            let dragInteraction = UIDragInteraction(delegate: delegate)
            let dropInteraction = UIDropInteraction(delegate: delegate)
            dragInteraction.isEnabled = true
            view.addInteraction(dragInteraction)
            view.addInteraction(dropInteraction)
            stackView.addArrangedSubview(view)
        }
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnStackView(_:))))
        numberView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnNumberView(_:))))
        
        stackView.isHidden = cells.isEmpty
        placeholderView.isHidden = !cells.isEmpty
        if cells.isEmpty {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    @objc
    func flash(at itemIndex: Int) {
        cells.reversed()[itemIndex].flash()
    }
    
    @objc
    func selectRow() {
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    @objc
    func selectRowItem(at index: Int) {
        guard index > 0 else {
            return
        }
        let cell = cells.filter { $0.tag == index }.first
        cell?.layer.borderWidth = 2.0
        cell?.layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    @objc
    func highlightRowItem(at index: Int) {
        guard index > 0 else {
            return
        }
        let cell = cells.filter { $0.tag == index }.first
        cell?.lightboxHighlight()
    }
    
    @objc
    func deselectRow() {
        layer.borderWidth = 0.0
        layer.borderColor = UIColor.clear.cgColor
    }
    
    @objc
    func deselectAll() {
        deselectRow()
        for cell in cells {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    @objc
    func set(paintImage: UIImage?, pencilImage: UIImage?, for index: Int) {
        guard index > 0 else {
            return
        }
        let cell = cells.filter { $0.tag == index }.first
        cell?.setImages(pencil: pencilImage, paint: paintImage)
    }
    
    @objc
    func getItemIndex(at point: CGPoint) -> Int {
        let cells = self.cells
        let x = point.x - numberView.frame.size.width;
        let width = stackView.frame.size.width / CGFloat(stackView.arrangedSubviews.count)
        for i in 1...cells.count {
            if x <= CGFloat(i) * width {
                return cells[i - 1].tag
            }
        }
        return -1
    }
    
    // MARK: -
    
    @objc
    private func tapOnNumberView(_ tapGestureRecognizer: UITapGestureRecognizer) {
        selectRow()
        delegate?.xSheetTableViewCellDidTap(self)
    }
    
    @objc
    private func tapOnStackView(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let cells = self.cells
        let location = tapGestureRecognizer.location(in: stackView)
        for cell in cells {
            guard
                let location = tapGestureRecognizer.view?.convert(location, to: cell),
                cell.bounds.contains(location)
            else {
                continue
            }
            delegate?.xSheetTableViewCell(self, didTapOnItem: cell.tag)
            return
        }
    }
}

private extension FBCell {
    
    var frameType: FrameView.FrameType {
        if isEmpty() {
            return .empty
        }
        if isClear() {
            return .clear
        }
        return .content
    }
}
