//
//  MLTexture.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/18.
//

import Foundation
import Metal
import UIKit
import Accelerate

/// texture with UUID
open class MLTexture: Hashable {
    
    open private(set) var id: String
    
    open private(set) var texture: MTLTexture
    
    init(id: String, texture: MTLTexture) {
        self.id = id
        self.texture = texture
    }

    // size of texture in points
//    open lazy var size: CGSize = {
//        let scaleFactor = UIScreen.main.nativeScale
//        return CGSize(width: CGFloat(texture.width) / scaleFactor, height: CGFloat(texture.height) / scaleFactor)
//    }()

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MLTexture, rhs: MLTexture) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MTLTexture {
    
    /// get CIImage from this texture
    func toCIImage() -> CIImage? {
        let image = CIImage(mtlTexture: self, options: [
            .colorSpace: CGColorSpaceCreateDeviceRGB()
        ])
        return image?.oriented(forExifOrientation: 4)
    }
    
    /// get CGImage from this texture
    func toCGImage() -> CGImage? {
        guard let ciimage = toCIImage() else {
            return nil
        }
        let context = CIContext(mtlDevice: device) // Prepare for create CGImage
        let rect = CGRect(origin: .zero, size: ciimage.extent.size)
        return context.createCGImage(ciimage, from: rect)
    }
    
    /// get UIImage from this texture
    func toUIImage() -> UIImage? {
        guard let cgimage = toImage() else {
            return nil
        }
        return UIImage(cgImage: cgimage)
    }
    
    /// get data from this texture
    func toData() -> Data? {
        guard let image = toUIImage() else {
            return nil
        }
        return image.pngData()
    }
    
    func toFBImage() -> FBImage? {
        let data = bytes()
        return FBImage(straightImageBitmapData: data, width: width, height: height)
    }
    
}

extension MTLTexture {

    func bytes() -> Data {
        let width = self.width
        let height = self.height
        let rowBytes = self.width * 4
        
        var bytes = [UInt8](repeating: 0, count: rowBytes * height)

        self.getBytes(&bytes, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        return Data(bytes)
    }

    func toImage() -> CGImage? {
        let cfdata = bytes() as CFData

        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let fromBitmapInfo = CGImageAlphaInfo.first.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
//        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
//        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
//            return
//        }
//        let provider = CGDataProvider(dataInfo: nil, data: p, size: selftureSize, releaseData: releaseMaskImagePixelData)
        let provider = CGDataProvider(data: cfdata)
        let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: CGBitmapInfo(rawValue: fromBitmapInfo), provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        
        
//        var format = vImage_CGImageFormat(
//          bitsPerComponent: UInt32(cgImage.bitsPerComponent),
//          bitsPerPixel: UInt32(cgImage.bitsPerPixel),
//          colorSpace: Unmanaged.passRetained(pColorSpace),
//          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
//          version: 0, decode: nil,
//          renderingIntent: CGColorRenderingIntent.defaultIntent)
//        var sourceBuffer = vImage_Buffer()
//        defer {
//          free(sourceBuffer.data)
//        }
//        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
////        vImagePremultiplyData_RGBA8888(&sourceBuffer, &sourceBuffer, numericCast(kvImageNoFlags))
//        vImageUnpremultiplyData_RGBA8888(&sourceBuffer, &sourceBuffer, numericCast(kvImageNoFlags))
//
//
//        let destCGImage = vImageCreateCGImageFromBuffer(&sourceBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        
        return cgImage
    }
    
}
