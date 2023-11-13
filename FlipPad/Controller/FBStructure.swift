//
//  FBStructure.swift
//  FlipPad
//
//  Created by Alex on 09.05.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit

struct Pixel {
    
    public var value: UInt32
    
    public var B: UInt8 {
        get { return UInt8(value & 0xFF); }
        set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
    }
    
    public var G: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
    }
    
    public var R: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
    }
    
    public var A: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
    }
    
}

struct RGBAImage {
    
    class WrappedPixels {
        public var pixels: UnsafeMutableBufferPointer<Pixel>
        init() {
            pixels = UnsafeMutableBufferPointer(start: nil, count: 0)
        }
        deinit {
            pixels.deallocate()
        }
    }
    
    let wrappedPixels = WrappedPixels()
    public var width: Int
    public var height: Int
    
    public init?(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        width = Int(image.size.width)
        height = Int(image.size.height)
        
        let bytesPerRow = width * 4
        let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
        //if we don't initialize it, the toUIImage() method will generate extra color.
        imageData.initialize(repeating: Pixel(value: 0), count: width*height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo = bitmapInfo | CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        imageContext.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        
        wrappedPixels.pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
    }
    
    public func toUIImage() -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        let bytesPerRow = width * 4
        
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let imageContext = CGContext(data: wrappedPixels.pixels.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil) else {
            return nil
        }
        
        guard let cgImage = imageContext.makeImage() else {
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    public func hasTransparentPixelsAround(x: Int, y: Int) -> Bool {
        func pixel(x: Int, y: Int) -> Pixel {
            let index = y * width + x
            return wrappedPixels.pixels[index]
        }
        
        // Top
        if (y > 0) {
            if pixel(x: x, y: y - 1).A == 0 {
                return true
            }
            // Top-Left
            if (x > 0) && pixel(x: x - 1, y: y - 1).A == 0 {
                return true
            }
            // Top-Right
            if (x < width - 1) && pixel(x: x + 1, y: y - 1).A == 0 {
                return true
            }
        }
        // Left
        if (x > 0) && pixel(x: x - 1, y: y).A == 0 {
            return true
        }
        // Right
        if (x < width - 1) && pixel(x: x + 1, y: y).A == 0 {
            return true
        }
        // Bottom
        if (y < height - 1) {
            if pixel(x: x, y: y + 1).A == 0 {
                return true
            }
            // Bottom-Left
            if (x > 0) && pixel(x: x - 1, y: y + 1).A == 0 {
                return true
            }
            // Bottom-Right
            if (x < width - 1) && pixel(x: x + 1, y: y + 1).A == 0 {
                return true
            }
        }
        
        return false
    }
    
}

@objc class FBStructure: NSObject {

    @objc static func structureImage(from sourceImage: UIImage) -> UIImage {
        let image = RGBAImage(image: sourceImage)!

        for y in 0..<image.height {
            for x in 0..<image.width {
                let index = y * image.width + x
                // Remove light transparency
                if image.wrappedPixels.pixels[index].A < 15 {
                    image.wrappedPixels.pixels[index].A = 0
                }
                // ??
            }
        }

        return image.toUIImage()!
    }
    
}

@objc class FBPencil: NSObject {

    @objc static func pencilImage(from sourceImage: UIImage) -> UIImage {
        let image = RGBAImage(image: sourceImage)!

        for y in 0..<image.height {
            for x in 0..<image.width {
                let index = y * image.width + x
                // Remove if close to white
                let sum = Int(image.wrappedPixels.pixels[index].R) + Int(image.wrappedPixels.pixels[index].G) + Int(image.wrappedPixels.pixels[index].B)
                let maxSum = Int(UInt8.max) * 3
                if (maxSum - sum) < 128 {
                    image.wrappedPixels.pixels[index].A = 0
                }
                // ??
            }
        }
        
        let imageCopy = RGBAImage(image: image.toUIImage()!)!
        
        for y in 0..<image.height {
            for x in 0..<image.width {
                let index = y * image.width + x
                // if has transparent neighbours
                if imageCopy.wrappedPixels.pixels[index].A != 0 && imageCopy.hasTransparentPixelsAround(x: x, y: y) {
                    image.wrappedPixels.pixels[index].A = 0
                }
                // ??
            }
        }

        return image.toUIImage()!
    }
    
}
