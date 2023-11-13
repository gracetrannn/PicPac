//
//  DCFBStorage.swift
//  FlipPad
//
//  Created by Alex on 08.07.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import Foundation

class FBCachedCell {
    // If not edited - can be unloaded
    var cell: FBCell?
    
    // Up to date
    var row: Int
    var column: Int
    
    init(cell: FBCell?, row: Int, column: Int) {
        self.cell = cell
        
        self.row = row
        self.column = column
    }
}

@objc class FBXsheetStorage: NSObject, FBStorage {
    
    // MARK: - Read & Write
    
    @objc var database: FBSceneDatabase!
    private let cache = FBXsheetCache()
    private let cacheComposite = FBXsheetCompositeCache()
    private var cacheCurrentCellOriginal: FBCellOriginal? = nil
    
    @objc init(database: FBSceneDatabase) {
        super.init()
        
        self.database = database
        numberOfRows = database.maxRow()
    }
    
    @objc var numberOfRows: Int = 0
    @objc var numberOfColumns: Int {
        get {
            if let database = database as? FBDCFBSceneDatabase {
                return database.maxDesiredColumn()
            } else {
                return database.maxColumn()
            }
        }
        set {
            if let database = database as? FBDCFBSceneDatabase {
                return database.setMaxDesiredColumn(newValue)
            } else {
                //
            }
        }
    }
    
    @objc var previewImage: UIImage? {
        let isStraightAlpha = database.isStraightAlpha()
        if isStraightAlpha {
            return compositeAt(row: 1);
        } else {
            return compositeImage(row: 1);
        }
    }
    
    @objc func compositeImage(row: Int) -> UIImage? {
        var images = [UIImage]()

        let isStraightAlpha = database.isStraightAlpha()
        
        func addedImagesBy(cell: FBCell) {
            if cell.isBackground() {
                if !cell.isClear(), let backgroundImage = cell.backgroundImage?.previewUiImage {
                    images.append(backgroundImage)
                }
            } else {
                if !cell.isClear(), let paintImage = cell.paintImage?.previewUiImage {
                    images.append(paintImage)
                }
                if !cell.isClear(), let pencilImage = cell.pencilImage?.previewUiImage {
                    images.append(pencilImage)
                }
            }
        }
        
        func addedImagesByOld(cell: FBOldCell) {
            if !cell.isClear(), let paintImage = cell.paintImage {
                images.append(paintImage)
            }
            if !cell.isClear(), let pencilImage = cell.pencilImage {
                images.append(pencilImage)
            }
        }

        for col in 1...numberOfColumns {
            if isStraightAlpha {
                if let cell = cellAt(row: row, column: col), !cell.isEmpty() {
                    addedImagesBy(cell: cell)
                } else {
                    var rowCell = row - 1
                    while rowCell > 0 {
                        if let cell = cellAt(row: rowCell, column: col), !cell.isEmpty() {
                            addedImagesBy(cell: cell)
                            break
                        } else {
                            rowCell -= 1
                        }
                    }
                }
            } else {
                if let cell = old_cellAt(row: row, column: col), !cell.isEmpty() {
                    addedImagesByOld(cell: cell)
                } else {
                    var rowCell = row - 1
                    while rowCell > 0 {
                        if let cell = old_cellAt(row: rowCell, column: col), !cell.isEmpty() {
                            addedImagesByOld(cell: cell)
                            break
                        } else {
                            rowCell -= 1
                        }
                    }
                }
            }
        }
        
        let composedImage = UIImage.rf_image(byCompositingImages: images, backgroundColor: UIColor.white)
        
        return composedImage;
    }
    
    // MARK: - Adding / Delete Row and Columns
    
    @objc func fillEmptyRows(count: Int) {
        for row in 1...count {
            for column in 1...numberOfColumns {
//                storeCell(FBCel.empty(), atRow: row, column: column)
                storeCell(FBCell.emptyCel(), atRow: row, column: column)
            }
        }
        numberOfRows = count
    }
    
    @objc func insertRowAfter(row: Int) {
        shiftAllCellsForward(startingFromRow: row)
        for column in 1...numberOfColumns {
//            storeCell(FBCell.empty(), atRow: row + 1, column: column)
            storeCell(FBCell.emptyCel(), atRow: row, column: column)
        }
        numberOfRows += 1
    }
    
    private func shiftAllCellsForward(startingFromRow row: Int) {
        print("Shifting forward starting from", row)
        guard numberOfRows >= row else {
            return
        }
        // DB
        database.shiftCellsForwardStarting(fromRow: row)
        // CACHE
        cache.shiftCellsForwardStarting(fromRow: row)
        cacheComposite.shiftCompositesForwardStarting(fromRow: row)
    }
    
    private func shiftAllCellsBackward(startingFromRow row: Int) {
        print("Shifting backward starting from", row)
        guard numberOfRows >= row else {
            return
        }
        // DB
        database.shiftCellsBackwardStarting(fromRow: row)
        // CACHE
        cache.shiftCellsBackwardStarting(fromRow: row)
        cacheComposite.shiftCompositesBackwardStarting(fromRow: row)
    }
    
    @objc func insertColumnAfter(column: Int) {
        shiftAllCellsForward(startingFromColumn: column)
        for row in 1...numberOfRows {
            storeCell(FBCell.emptyCel(), atRow: row, column: column)
        }
    }

    private func shiftAllCellsForward(startingFromColumn column: Int) {
        print("Shifting forward starting from column", column)
        guard numberOfColumns >= column else {
            return
        }
        // DB
        database.shiftCellsForwardStarting(fromColumn: column)
        database.shiftToLeftLevels(fromColumn: column)
        // CACHE
        cache.shiftCellsForwardStarting(fromColumn: column)
    }

    private func shiftAllCellsBackward(startingFromColumn column: Int) {
        print("Shifting backward starting from column", column)
        guard numberOfColumns >= column else {
            return
        }
        // DB
        database.shiftCellsBackwardStarting(fromColumn: column)
        database.shiftToRightLevels(fromColumn: column)
        // CACHE
        cache.shiftCellsBackwardStarting(fromColumn: column)
        compositeUpdateCacheForRowsWith(start: 1, end: numberOfRows)
    }
    
    @objc func delete(row: Int) {
        // DB
        database.deleteRow(row)
        
        // CACHE
        for column in 1...numberOfColumns {
            cache.delete(row: row, column: column)
        }
        cacheComposite.delete(row: row)
        
        // Shift rows
        shiftAllCellsBackward(startingFromRow: row)
        numberOfRows -= 1
        compositeUpdateCacheForRowsWith(start: row, end: numberOfRows)
    }
    
    @objc func delete(column: Int) {
        // DB
        database.deleteColumn(column)
        database.setLevelName(nil, at: column)
        
        // CACHE
        for row in 1...numberOfRows {
            cache.delete(row: row, column: column)
        }
        
        // Shift rows
        shiftAllCellsBackward(startingFromColumn: column)
        compositeUpdateCacheForRowsWith(start: 1, end: numberOfRows)
    }
    
    // MARK: - Get & Set Cell
    
    // OLD DATABASE ACCESS
    private func old_fetchCellFromDatabaseAt(row: Int, column: Int) -> FBOldCell {
        let cell = FBOldCell()
        guard let database = database as? FBDCFBSceneDatabase else { fatalError("Error: Only DCFB scene databases support conversion") }
        cell.pencilImage = database.old_imagePencil(forRow: row, column: column)
        cell.paintImage = database.old_imagePaint(forRow: row, column: column)
        cell.structureImage = database.old_imageStructure(forRow: row, column: column)
        return cell
    }
        
    @objc func old_cellAt(row: Int, column: Int) -> FBOldCell? {
        let cellFormDB = old_fetchCellFromDatabaseAt(row: row, column: column)
        return cellFormDB
    }
    
    // NEW DATABASE ACCESS
    private func fetchCellFromDatabaseAt(row: Int, column: Int) -> FBCell {
        let cell = FBCell()
        cell.pencilImage = database.imagePencil(forRow: row, column: column)
        cell.paintImage = database.imagePaint(forRow: row, column: column)
        cell.structureImage = database.imageStructure(forRow: row, column: column)
//        let pr = cell.structureImage?.previewUiImage
        cell.backgroundImage = database.imageBackground(forRow: row, column: column)
        return cell
    }
        
    @objc func cellAt(row: Int, column: Int) -> FBCell? {
        if let cachedCell = cache.fetchCellFromCacheAt(row: row, column: column) {
            return cachedCell.cell
        } else {
            let cellFormDB = fetchCellFromDatabaseAt(row: row, column: column)
            cache.cacheCell(FBCachedCell(cell: cellFormDB, row: row, column: column))
            return cellFormDB
        }
    }
    
    @objc func reloadCellAt(row: Int, column: Int) -> FBCell? {
        cache.delete(row: row, column: column)
        let cellFormDB = fetchCellFromDatabaseAt(row: row, column: column)
        cache.cacheCell(FBCachedCell(cell: cellFormDB, row: row, column: column))
        return cellFormDB
    }
    
    private func fetchCellOriginalFromDatabaseAt(row: Int, column: Int) -> FBCellOriginal {
        let cell = FBCellOriginal()
        cell.frame = row
        cell.level = column
        cell.pencilImage = database.imageOriginalPencil(forRow: row, column: column)
        cell.paintImage = database.imageOriginalPaint(forRow: row, column: column)
        cell.backgroundImage = database.imageOriginalBackground(forRow: row, column: column)
        return cell
    }
    
    @objc func cellOriginalAt(row: Int, column: Int) {
        if cacheCurrentCellOriginal != nil {
            if cacheCurrentCellOriginal?.frame != row || cacheCurrentCellOriginal?.level != column {
                cacheCurrentCellOriginal = fetchCellOriginalFromDatabaseAt(row: row, column: column)
            }
        } else {
            cacheCurrentCellOriginal = fetchCellOriginalFromDatabaseAt(row: row, column: column)
        }
    }
    
    @objc func reloadCellOriginalAt(row: Int, column: Int) {
        cacheCurrentCellOriginal = fetchCellOriginalFromDatabaseAt(row: row, column: column)
    }
    
    @objc func getCellOriginalAt(row: Int, column: Int) -> FBCellOriginal? {
        cellOriginalAt(row: row, column: column)
        return cacheCurrentCellOriginal
    }
    
    //
    
    @objc func previousCellAt(row: Int, column: Int) -> FBCell? {
        return previousCellAt(row: row, column: column, resultingRow: nil)
    }
    
    @objc func previousCellAt(row: Int, column: Int, resultingRow: UnsafeMutablePointer<Int>?) -> FBCell? {
        var result: FBCell?
        var _row = row - 1
        while _row > 0 && result?.isEmpty() ?? true {
            result = cellAt(row: _row, column: column)
            _row -= 1
        }
        resultingRow?.pointee = _row + 1
        return result
    }
    
    @objc func firstValidCell() -> FBCell? {
        for row in 1...numberOfRows {
            for col in 1...numberOfColumns {
                if let cell = cellAt(row: row, column: col), !cell.isEmpty() {
                    return cell
                }
            }
        }
        return nil
    }
    
    @objc func storeCell(_ cell: FBCell?, atRow row: Int, column: Int) {
        // DB
        database.setPencilImage(cell?.pencilImage, forRow: row, column: column)
        database.setPaint(cell?.paintImage, forRow: row, column: column)
        database.setStructureImage(cell?.structureImage, forRow: row, column: column)
        // CACHE
        cache.cacheCell(FBCachedCell(cell: cell, row: row, column: column))
    }
    
    @objc func storeCellOriginal(_ cell: FBCellOriginal?, atRow row: Int, column: Int) {
        // DB
        database.setOriginalPencilImage(cell?.pencilImage, forRow: row, column: column)
        database.setOriginalPaintImage(cell?.paintImage, forRow: row, column: column)
        // CACHE
//        cache.cacheCell(FBCachedCell(cell: cell, row: row, column: column))
    }
    
    // MARK: - Get & Set Composite
    
    private func fetchCompositeFromDatabaseAt(row: Int) -> UIImage? {
        return compositeImage(row: row);
    }

    @objc func compositeAt(row: Int) -> UIImage? {
        return fetchCompositeFromDatabaseAt(row: row)
    }
    
    @objc func compositeUpdateCacheForRowsWith(start: Int, end: Int) {
        if start <= end {
            for row in start...end {
                cacheComposite.delete(row: row)
                let compositeFormDB = fetchCompositeFromDatabaseAt(row: row)
                cacheComposite.cacheComposite(compositeFormDB, row: row)
            }
        }
    }
    
    @objc func compositeUpdateCacheFor(row: Int, column: Int) {
        var endRow = row
        
        if ((row + 1) <= numberOfRows) {
            for rowIndex in (row + 1)...numberOfRows {
                if let cell = cellAt(row: rowIndex, column: column), cell.isEmpty() {
                    endRow += 1
                } else {
                    break
                }
            }
        }

        compositeUpdateCacheForRowsWith(start: row, end: endRow)
    }
    
    // MARK: - Hold
    
    @objc func setHoldFor(row: Int, column: Int, toValue: Int) {
        let current_hold: Int = getHoldFor(row: row, column: column)
            
        if (toValue > current_hold) {
            // push other rows forward
            let diff = toValue - current_hold
            for _ in 0..<diff {
                insertRowAfter(row: row)
            }
        } else if (toValue < current_hold) {
            // pull other rows back
            let diff = current_hold - toValue
            for _ in 0..<diff {
                delete(row: row + 1)
                insertRowAfter(row: numberOfRows)
            }
        }
    }
    
    @objc func getHoldFor(row: Int, column: Int) -> Int {
        var i = row + 1
        var count = 1
        while (i <= numberOfRows) {
            let cel = cellAt(row: i, column: column)
            if let cel = cel, !cel.isEmpty() {
                break
            } else {
                count += 1
                i += 1
            }
        }
        return count
    }
    
    @objc func isHoldAt(row: Int, column: Int) -> Bool {
        let cell = cellAt(row: row, column: column)
        return cell?.isEmpty() ?? true
    }
    
    // MARK: - Cache
    
    @objc func updateCacheFor(rows: IndexSet) {
        cache.updateCacheFor(rows: rows, columnsCount: numberOfColumns)
    }
    
    // MARK: -
    
    @objc func getLevelWidth(level: NSInteger, twidth: NSInteger) -> NSInteger {
        return database.getLevelWidth(forLevel:level, twidth:twidth);
    }
}
