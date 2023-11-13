//
//  FBImage+Fill.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 7/1/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import Foundation

fileprivate class Filling {
    
    static var isOnFill = false
}

extension FBImage {
    
    @objc func fill(at point: CGPoint, structure: FBImage, color: CGColor, threshold: Int, colorToErase: CGColor? = nil) {
        
        if Filling.isOnFill {
            return
        }
        Filling.isOnFill = true
        defer {
            Filling.isOnFill = false
        }
        
        var fillValue: [UInt8] = color.components!.map { UInt8($0 * CGFloat(UInt8.max)) }
        var fillValueToErase: [UInt8]? = colorToErase?.components?.map { UInt8($0 * CGFloat(UInt8.max)) }
        
        let r = fillValue[0]
        let b = fillValue[2]
        fillValue[0] = b
        fillValue[2] = r
        
        let _r = fillValueToErase?[0] ?? 0
        let _b = fillValueToErase?[2] ?? 0
        fillValueToErase?[0] = _b
        fillValueToErase?[2] = _r
        
        // Same for both images
        
        let rowAdjustedWidth = Int(imageBuffer.rowBytes)
        
        /*
        let rowWidth = Int(imageBuffer.width * 4)
         */
        
        let width = Int(imageBuffer.width)
        let height = Int(imageBuffer.height)
        let length = height * rowAdjustedWidth
        
        let fillImageBuffer = imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        let structureImageBuffer = structure.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        
        let isEraser = colorToErase != nil
        
        // Pixel access funcs.
        
        func PIXEL_TO_INDEX(_ x: Int, _ y: Int) -> Int {
            return x * 4 + y * rowAdjustedWidth
        }
        
        func INDEX_TO_X(_ index: Int) -> Int {
            return index % rowAdjustedWidth / 4
        }
        
        func INDEX_TO_Y(_ index: Int) -> Int {
            return index / rowAdjustedWidth
        }
        
        func PIXEL_STRUCTURE_PTR(_ x: Int, _ y: Int) -> UnsafeMutablePointer<UInt8> {
            return structureImageBuffer + PIXEL_TO_INDEX(x, y)
        }
        
        func PIXEL_FILL_PTR(_ x: Int, _ y: Int) -> UnsafeMutablePointer<UInt8> {
            return fillImageBuffer + PIXEL_TO_INDEX(x, y)
        }
        
        /*
        func DIFF(_ a: UInt8, _ b: UInt8) -> Int {
            return Int(max(a, b) - min(a, b))
        }
        
        func PIXEL_DIFF(_ ptr1: UnsafePointer<UInt8>, _ ptr2: UnsafePointer<UInt8>) -> Int {
            return DIFF((ptr1 + 0).pointee, (ptr2 + 0).pointee)
            + DIFF((ptr1 + 1).pointee, (ptr2 + 1).pointee)
            + DIFF((ptr1 + 2).pointee, (ptr2 + 2).pointee)
            + DIFF((ptr1 + 3).pointee, (ptr2 + 3).pointee)
        }
        */
        
        func IS_CLEAR(_ ptr: UnsafePointer<UInt8>) -> Bool {
            return (ptr + 0).pointee == 0
            && (ptr + 1).pointee == 0
            && (ptr + 2).pointee == 0
            && (ptr + 3).pointee == 0
        }
        
        func IS_LOWER_THAN_THRES(_ ptr: UnsafePointer<UInt8>) -> Bool {
            return (ptr + 3).pointee <= threshold
        }
        
        func IS_SAME(_ ptr: UnsafePointer<UInt8>) -> Bool {
            return (ptr + 0).pointee == fillValue[0]
            && (ptr + 1).pointee == fillValue[1]
            && (ptr + 2).pointee == fillValue[2]
            && (ptr + 3).pointee == fillValue[3]
        }
        
        func IS_SAME_ERASER(_ ptr: UnsafePointer<UInt8>) -> Bool {
            guard let fillValueToErase = fillValueToErase else {
                return false
            }
            return (ptr + 0).pointee == fillValueToErase[0]
            && (ptr + 1).pointee == fillValueToErase[1]
            && (ptr + 2).pointee == fillValueToErase[2]
            && (ptr + 3).pointee == fillValueToErase[3]
        }
        
        func FILL(_ x: Int, _ y: Int) {
            let ptr = PIXEL_FILL_PTR(x, y)
            (ptr + 0).pointee = fillValue[0]
            (ptr + 1).pointee = fillValue[1]
            (ptr + 2).pointee = fillValue[2]
            (ptr + 3).pointee = fillValue[3]
        }
        
        func ERASE(_ x: Int, _ y: Int) {
            let ptr = PIXEL_FILL_PTR(x, y)
            (ptr + 0).pointee = 0
            (ptr + 1).pointee = 0
            (ptr + 2).pointee = 0
            (ptr + 3).pointee = 0
        }
        
        func CONDITION(_ x: Int, _ y: Int) -> Bool {
            let fillPtr          = PIXEL_FILL_PTR(x, y)
            let structurePtr     = PIXEL_STRUCTURE_PTR(x, y)
            let isClearStr       = IS_CLEAR(structurePtr)
            let isLowerStr       = IS_LOWER_THAN_THRES(structurePtr)
            let isSameFill       = IS_SAME(fillPtr)
            let isClearFill      = IS_CLEAR(fillPtr)
            let isSameEraserFill = IS_SAME_ERASER(fillPtr)
            if isEraser {
                return isSameEraserFill && (isClearStr || isLowerStr)
            }
            return (isClearStr || isLowerStr) && (isClearFill || !isSameFill)
        }
        
        // Fill.
        
        var set = Set<Int>()
        set.reserveCapacity(width * height)
        
        let startX = Int(point.x)
        let startY = Int(point.y)
        
        set.insert(PIXEL_TO_INDEX(startX, startY))
        
        while !set.isEmpty {
            
            let index = set.first!
            set.remove(index)
            
            let x = INDEX_TO_X(index)
            let y = INDEX_TO_Y(index)
            
            // Fill source point.
            if isEraser {
                ERASE(x, y)
            } else {
                FILL(x, y)
            }
            
            // Fill line before source point.
            var minX = x - 1
            while true {
                let inBounds = 0 <= minX
                if !inBounds {
                    break
                }
                if !CONDITION(minX, y) {
                    break
                }
                if isEraser {
                    ERASE(minX, y)
                } else {
                    FILL(minX, y)
                }
                minX -= 1
            }
            
            // Fill line after source point.
            var maxX = x + 1
            while true {
                let inBounds = maxX < width
                if !inBounds {
                    break
                }
                if !CONDITION(maxX, y) {
                    break
                }
                if isEraser {
                    ERASE(maxX, y)
                } else {
                    FILL(maxX, y)
                }
                maxX += 1
            }
            
            if minX < 0 {
                minX = 0
            }
            
            if maxX >= width {
                maxX = width - 1
            }
            
            if minX + 1 >= maxX - 1 {
                continue
            }
            
            for _y in (y - 1)...(y + 1) {
                if 0 <= _y && _y < height {
                    var flag = true
                    for _x in (minX + 1)...(maxX - 1) {
                        if CONDITION(_x, _y) {
                            if flag {
                                let pixel = PIXEL_TO_INDEX(_x, _y)
                                set.insert(pixel)
                                flag = false
                            }
                        } else {
                            flag = true
                        }
                    }
                }
            }
        }
    }
}
