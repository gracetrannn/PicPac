//
//  CGImage+Extras.swift
//  FlipPad
//
//  Created by Alex on 23.07.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGImage {
    
    func pixelColorAt(_ location: CGPoint) -> CGColor {
        return self.pixelColorAt(x: Int(location.x), y: Int(location.y))
    }
    
    func pixelColorAt(x: Int, y: Int) -> CGColor {
        let pixelData = self.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelSize = bitsPerPixel / 8
        
        guard (Int(self.width) * Int(self.height) * pixelSize) == (CFDataGetLength(pixelData)) else {
            return UIColor.clear.cgColor
        }
        
        let pixelInfo: Int = ((Int(self.width) * y) + x) * pixelSize

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        
        switch pixelSize {
        case 4:
            b = CGFloat(data[pixelInfo]) / CGFloat(255.0)
            g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
            r = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
            a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        case 8:
            b = CGFloat( Int(data[pixelInfo]) + 255 * Int(data[pixelInfo+1]) ) / CGFloat(255.0 * 255.0)
            g = CGFloat( Int(data[pixelInfo+2]) + 255 * Int(data[pixelInfo+3]) ) / CGFloat(255.0 * 255.0)
            r = CGFloat( Int(data[pixelInfo+4]) + 255 * Int(data[pixelInfo+5]) ) / CGFloat(255.0 * 255.0)
            a = CGFloat( Int(data[pixelInfo+6]) + 255 * Int(data[pixelInfo+7]) ) / CGFloat(255.0 * 255.0)
        default:
            break
        }
        
        switch alphaInfo {
        case .premultipliedLast:
            r = r / a
            g = g / a
            b = b / a
        default:
            break
        }
        
        return UIColor(red: r, green: g, blue: b, alpha: a).cgColor
    }
    
}

typealias ColorComponents = (b: UInt8, g: UInt8, r: UInt8, a: UInt8)

extension CGImage {
    
    func color(at: CGPoint) -> ColorComponents? {
        let pixelData = self.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelSize = bitsPerPixel / 8
        
        guard (Int(self.width) * Int(self.height) * pixelSize) == (CFDataGetLength(pixelData)) else {
            return nil
        }
        
        let pixelInfo: Int = ((Int(self.width) * Int(at.y)) + Int(at.x)) * pixelSize
        
        var b: UInt8 = 0
        var g: UInt8 = 0
        var r: UInt8 = 0
        var a: UInt8 = 0
        
        switch pixelSize {
        case 4:
            switch bitmapInfo.pixelFormat {
            case .bgra:
                b = data[pixelInfo]
                g = data[pixelInfo+1]
                r = data[pixelInfo+2]
                a = data[pixelInfo+3]
            case .rgba:
                r = data[pixelInfo]
                g = data[pixelInfo+1]
                b = data[pixelInfo+2]
                a = data[pixelInfo+3]
            case .abgr:
                a = data[pixelInfo]
                b = data[pixelInfo+1]
                g = data[pixelInfo+2]
                r = data[pixelInfo+3]
            case .argb:
                a = data[pixelInfo]
                r = data[pixelInfo+1]
                g = data[pixelInfo+2]
                b = data[pixelInfo+3]
            default:
                break
            }
        case 8:
            //
            break
        default:
            break
        }
        
        return (b, g, r, a)
    }
    
}

