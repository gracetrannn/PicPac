//
//  UIImage+Extras.swift
//  FlipPad
//
//  Created by Alex on 21.02.2020.
//  Copyright © 2020 Alex. All rights reserved.
//

import UIKit
import VideoToolbox

extension UIImage {
    
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let _cgImage = cgImage else {
            return nil
        }

        self.init(cgImage: _cgImage)
    }
    
}

extension UIImage {
    
    func crop(rect: CGRect) -> UIImage {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale

        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    static func clearImageOf(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        UIColor.clear.set()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}

extension UIImage {

    @objc func imageByApplyingClippingBezierPath(_ path: UIBezierPath) -> UIImage {
        // Mask image using path
        let result = imageByApplyingMaskingBezierPath(path).crop(rect: path.bounds)
        return result
    }

    @objc func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        context.interpolationQuality = .high
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(x: 0, y: 0, width: cgImage!.width, height: cgImage!.height))
        
        // Set the clipping mask
        context.addPath(path.cgPath)
        context.clip()
        
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        
        return img
    }
    
    @objc func imageByApplyingCuttingBezierPath(_ path: UIBezierPath) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        context.interpolationQuality = .high
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(x: 0, y: 0, width: cgImage!.width, height: cgImage!.height))
        
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        // Clip to the bezier path and clear that portion of the image.
        context.addPath(path.cgPath)
        context.clip()
        context.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        // Build a new UIImage from the image context.
        
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        context.restoreGState()
        UIGraphicsEndImageContext()
        
        return img
    }

}

extension UIImage {
    
    @objc func pixelColorAt(x: Int, y: Int) -> UIColor {
        let color = cgImage!.pixelColorAt(x: x, y: y)
        return UIColor(cgColor: color)
    }
    
}
