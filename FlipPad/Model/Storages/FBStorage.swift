//
//  FBStorage.swift
//  FlipPad
//
//  Created by Alex on 08.07.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit

protocol FBStorage: class {
    
    // MARK: - Read & Write
    
    var database: FBSceneDatabase! { get set }
    
    var numberOfRows: Int { get set }
    var numberOfColumns: Int { get set }
    
    var previewImage: UIImage? { get }
    
    func fillEmptyRows(count: Int)
    func insertRowAfter(row: Int)
    
    // MARK: - Get Cell
    
    func old_cellAt(row: Int, column: Int) -> FBOldCell?
    func cellAt(row: Int, column: Int) -> FBCell?
    func previousCellAt(row: Int, column: Int) -> FBCell?
    
    // MARK: - Delete
    
    func delete(row: Int)
    func delete(column: Int)
    
    // MARK: - Hold
    
    func setHoldFor(row: Int, column: Int, toValue: Int)
    func getHoldFor(row: Int, column: Int) -> Int
    func isHoldAt(row: Int, column: Int) -> Bool
    
}
