//
//  FBImage.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 5/17/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit
import Accelerate
import CoreServices
import Cpng
import opencv2

@objc class FBImage: NSObject {
    
    var imageBuffer = vImage_Buffer()
    
    // BGRA format
    var straighFormat = vImage_CGImageFormat()
    
    private override init() {
        super.init()
    }
    
    /**
     Used for initial creation of FBImage-s from regular UIImage-s
     */
    @objc convenience init?(premultipliedImage: UIImage) {
        guard let premultipliedCgImage = premultipliedImage.cgImage else {
            return nil
        }
        
        self.init(straightImage: premultipliedCgImage)
        
        // Unpremultiply
        
        let map: [UInt8]
        switch premultipliedCgImage.bitmapInfo.pixelFormat {
        case .abgr:
            map = [1, 2, 3, 0]
        case .argb:
            map = [3, 2, 1, 0]
        case .bgra:
            map = []
        case .rgba:
            map = [2, 1, 0, 3]
        case .none:
            // Unexpected image format
            return nil
        }
        if !map.isEmpty {
            vImagePermuteChannels_ARGB8888(&self.imageBuffer, &self.imageBuffer, map, vImage_Flags(kvImageNoFlags))
        }
        vImageUnpremultiplyData_RGBA8888(&self.imageBuffer, &self.imageBuffer, vImage_Flags(kvImageNoFlags))
    }
    
    /**
     Used for intializing FBImage with straigh alpha image PNG datas
     */
    @objc convenience init?(straightImagePNGData: Data) {
        let SIG_LEN: Int32 = 8
        var stream = InputStream(data: straightImagePNGData.dropFirst(Int(SIG_LEN)))
        stream.open()
        var png_ptr: png_structp? = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        var info_ptr: png_infop? = png_create_info_struct(png_ptr)

        png_set_read_fn(png_ptr, &stream) { png_ptr, outBytes, byteCountToRead in
            let io_ptr: png_voidp = png_get_io_ptr(png_ptr)
            let _stream = io_ptr.load(as: InputStream.self)
            let numberOfBytesRead = _stream.read(outBytes!, maxLength: byteCountToRead)
            print("Read", numberOfBytesRead, "/", byteCountToRead)
        }
    
        png_set_sig_bytes(png_ptr, SIG_LEN)
        
        png_read_info(png_ptr, info_ptr)

        var width: png_uint_32 = 0
        var height: png_uint_32 = 0
        var bitDepth: Int32 = 0
        var colorType: Int32 = -1
        let retval: png_uint_32 = png_get_IHDR(png_ptr, info_ptr, &width, &height, &bitDepth, &colorType, nil, nil, nil)
        print(retval)
        
        let rowLength = Int(width) * 4
        let bufferLength = Int(height) * rowLength
        
        let bufferPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
        bufferPointer.initialize(repeating: 0, count: bufferLength)
        
        for row in Array(0..<Int(height)) {
            let offset = row * rowLength
            let ptr = bufferPointer + offset
            png_read_row(png_ptr, ptr, nil)
        }
        
//        let _png_ptr = UnsafeRawPointer(&png_ptr).load(as: png_structpp.self)
//        let _info_ptr = UnsafeRawPointer(&info_ptr).load(as: png_infopp.self)
//
//        png_destroy_read_struct(_png_ptr, _info_ptr, nil)
        
        png_destroy_read_struct(&png_ptr, &info_ptr, nil)
        
        let data = Data(bytes: bufferPointer, count: bufferLength)
        self.init(straightImageBitmapData: data, width: Int(width), height: Int(height))
        
        vImagePermuteChannels_ARGB8888(&self.imageBuffer, &self.imageBuffer, [2, 1, 0, 3], vImage_Flags(kvImageNoFlags))
        
        stream.close()
        free(bufferPointer)
    }
    
    /**
     Used for intializing FBImage with straigh alpha bitmap data of BGRA format
     */
    @objc convenience init?(straightImageBitmapData: Data?, width: Int, height: Int) {
        guard let straightImageBitmapData = straightImageBitmapData else { return nil }
        let dp = CGDataProvider(data: straightImageBitmapData as CFData)!
        let bitmapInfo = CGImageAlphaInfo.first.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let img = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo), provider: dp, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        self.init(straightImage: img)
    }
    
    private init?(straightImage: CGImage) {
        var originalFormat = vImage_CGImageFormat(bitsPerComponent: UInt32(straightImage.bitsPerComponent),
                                                  bitsPerPixel: UInt32(straightImage.bitsPerPixel),
                                                  colorSpace: Unmanaged.passUnretained(straightImage.colorSpace!),
                                                  bitmapInfo: straightImage.bitmapInfo,
                                                  version: 0,
                                                  decode: nil,
                                                  renderingIntent: .defaultIntent)
        
        vImageBuffer_InitWithCGImage(&self.imageBuffer,
                                     &originalFormat,
                                     nil, straightImage,
                                     vImage_Flags(kvImageNoFlags))

        let bitmapInfo = CGImageAlphaInfo.first.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        self.straighFormat = vImage_CGImageFormat(bitsPerComponent: UInt32(straightImage.bitsPerComponent),
                                                  bitsPerPixel: UInt32(straightImage.bitsPerPixel),
                                                  colorSpace: Unmanaged.passUnretained(straightImage.colorSpace!),
                                                  bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                                                  version: 0,
                                                  decode: nil,
                                                  renderingIntent: .defaultIntent)
    }
    
    /**
     Straight alpha PNG data of an image for saving to DB
     */
    @objc var straightImageBitmapData: Data {
        return Data(bytes: imageBuffer.data, count: imageBuffer.rowBytes * Int(imageBuffer.height))
    }
    
    /**
     Straight alpha PNG data of an image for saving to DB
     */
    @objc var straightImagePNGData: Data? {
        // TODO: Possible undesired changes to pixels - better to rewrite for using PNG library
        let data = NSMutableData()
        let cgImage = cgImage
        guard let destination = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nil) else {
            return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        if CGImageDestinationFinalize(destination) {
            return data as Data
        }
        return nil
    }
    
    /**
     CGImage with straight alpha
     */
    @objc var cgImage: CGImage {
        let rowAdjustedWidth = Int(self.imageBuffer.rowBytes)
        let rowWidth = Int(self.imageBuffer.width) * 6
        let height = Int(self.imageBuffer.height)
        let length = height * rowWidth
        
        let bufferPointer = self.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        let bufferData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bufferPointer, length, kCFAllocatorNull)
        
        let imageData = CFDataCreateMutable(kCFAllocatorDefault, length)!
        CFDataSetLength(imageData, length)
        
        for row in 0..<height {
            let sourceOffset = row * rowAdjustedWidth
            let destinationOffset = row * rowWidth
            //
            let destination = CFDataGetMutableBytePtr(imageData).advanced(by: destinationOffset)
            CFDataGetBytes(bufferData, CFRangeMake(sourceOffset, rowAdjustedWidth), destination)
        }
        
        let dp = CGDataProvider(data: imageData)!
        let bitmapInfo = CGImageAlphaInfo.first.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let img = CGImage(width: Int(self.imageBuffer.width),
                          height: Int(self.imageBuffer.height),
                          bitsPerComponent: 8, bitsPerPixel: 32,
                          bytesPerRow: rowWidth,
                          space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                          provider: dp, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        
        return img
    }
    
    @objc var previewCgImage: CGImage {
        let rowAdjustedWidth = Int(self.imageBuffer.rowBytes)
        let rowWidth = Int(self.imageBuffer.width) * 6
        let height = Int(self.imageBuffer.height)
        let length = height * rowWidth
        
        let bufferPointer = self.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        let bufferData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bufferPointer, length, kCFAllocatorNull)
        
        let imageData = CFDataCreateMutable(kCFAllocatorDefault, length)!
        CFDataSetLength(imageData, length)
        
        for row in 0..<height {
            let sourceOffset = row * rowAdjustedWidth
            let destinationOffset = row * rowWidth
            //
            let destination = CFDataGetMutableBytePtr(imageData).advanced(by: destinationOffset)
            CFDataGetBytes(bufferData, CFRangeMake(sourceOffset, rowAdjustedWidth), destination)
        }
        
        let dp = CGDataProvider(data: imageData)!
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let img = CGImage(width: Int(self.imageBuffer.width),
                          height: Int(self.imageBuffer.height),
                          bitsPerComponent: 8, bitsPerPixel: 32,
                          bytesPerRow: rowWidth,
                          space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                          provider: dp, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        
        return img
    }
    
    @objc var previewUiImage: UIImage {
        var img = UIImage(cgImage: previewCgImage)
        return img
    }
    
    @objc func copyImage() -> FBImage {
        let cp = FBImage()
        cp.straighFormat = straighFormat
        vImageBuffer_Init(&cp.imageBuffer, vImagePixelCount(size.height), vImagePixelCount(size.width), 32, vImage_Flags(kvImageNoFlags))
        vImageCopyBuffer(&self.imageBuffer, &cp.imageBuffer, 4, vImage_Flags(kvImageNoFlags))
        return cp
    }
    
    deinit {
        free(imageBuffer.data)
    }
    
}

extension FBImage {
    
    @objc var size: CGSize {
        return CGSize(width: CGFloat(imageBuffer.width), height: CGFloat(imageBuffer.height))
    }
    
}

extension FBImage {
    
    @objc convenience init?(size: CGSize, fillColor: UIColor) {
        self.init(premultipliedImage: UIImage.rf_image(with: size, fill: fillColor))
    }
    
}

extension FBImage {
    
//    static func imageByCompositing(images: [FBImage], backgroundColor: UIColor) -> FBImage {
//        return
//    }
    
    @objc func flippedHorizontally() -> FBImage {
        vImageHorizontalReflect_ARGB8888(&self.imageBuffer, &self.imageBuffer, vImage_Flags(kvImageNoFlags))
        return self
    }
    
    @objc func flippedVertically() -> FBImage {
        vImageVerticalReflect_ARGB8888(&self.imageBuffer, &self.imageBuffer, vImage_Flags(kvImageNoFlags))
        return self
    }
    
//    @objc func imageByApplying(transform: CGAffineTransform) -> FBImage {
//        var vImageTransform = vImage_AffineTransform(a: Float(transform.a),
//                                                       b: Float(transform.b),
//                                                       c: Float(transform.c),
//                                                       d: Float(transform.d),
//                                                       tx: Float(transform.tx),
//                                                       ty: Float(transform.ty))
//        let backgroundColor: [Pixel_8] = [0, 0, 0, 0]
//
//        var destinationBuffer = vImage_Buffer()
//        vImageBuffer_Init(&destinationBuffer, vImagePixelCount(size.height), vImagePixelCount(size.width), 32, vImage_Flags(kvImageNoFlags))
//
//        vImageAffineWarp_ARGB8888(&self.imageBuffer,
//                                  &destinationBuffer,
//                                  nil,
//                                  &vImageTransform,
//                                  backgroundColor,
//                                  vImage_Flags(kvImageBackgroundColorFill | kvImageHighQualityResampling))
//
//        free(imageBuffer.data)
//        self.imageBuffer = destinationBuffer
//
//        return self
//    }
    
    
    @objc func imageByApplying(transform: ImageTransform) -> FBImage {
        let width = Int32(size.width)
        let height = Int32(size.height)
        
        let source = Mat(rows: height, cols: width, type: CvType.make(0, channels: 4), data: Data(bytes: imageBuffer.data, count: imageBuffer.rowBytes * Int(height)))
        let destination = Mat(rows: height, cols: width, type: CvType.make(0, channels: 4))
        
        let matrix = Imgproc.getAffineTransform(src: transform.src, dst: transform.dst)
        
        Imgproc.warpAffine(src: source, dst: destination, M: matrix,
                           dsize: Size2i(width: width, height: height),
                           flags: InterpolationFlags.INTER_NEAREST.rawValue)

        memcpy(self.imageBuffer.data, destination.dataPointer(), self.imageBuffer.rowBytes * Int(height))

        return self
    }
    
    @objc
    func imageByAdding(_ image: FBImage?) -> FBImage {
        return imageByAdding(image, isSourceBelow: true)
    }
    
    @objc
    func imageByAdding(_ image: FBImage?, isSourceBelow: Bool) -> FBImage {
        guard let image = image else {
            return self
        }
        let length = Int(imageBuffer.height) * imageBuffer.rowBytes
        let sourceBufferPointer = imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        let targetBufferPointer = image.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        for i in 0..<(length / 4) {
            //
            let sourcePtr = sourceBufferPointer + (i * 4)
            let targetPtr = targetBufferPointer + (i * 4)
            //
            let b0_Ptr = (sourcePtr + 0)
            let g0_Ptr = (sourcePtr + 1)
            let r0_Ptr = (sourcePtr + 2)
            let a0_Ptr = (sourcePtr + 3)
            //
            let b1_Ptr = (targetPtr + 0)
            let g1_Ptr = (targetPtr + 1)
            let r1_Ptr = (targetPtr + 2)
            let a1_Ptr = (targetPtr + 3)
            //
            let _b0 = Double(b0_Ptr.pointee) / 255.0
            let _g0 = Double(g0_Ptr.pointee) / 255.0
            let _r0 = Double(r0_Ptr.pointee) / 255.0
            let _a0 = Double(a0_Ptr.pointee) / 255.0
            //
            let _b1 = Double(b1_Ptr.pointee) / 255.0
            let _g1 = Double(g1_Ptr.pointee) / 255.0
            let _r1 = Double(r1_Ptr.pointee) / 255.0
            let _a1 = Double(a1_Ptr.pointee) / 255.0
            //
            let a0 = isSourceBelow ? _a1 : _a0
            let r0 = isSourceBelow ? _r1 : _r0
            let g0 = isSourceBelow ? _g1 : _g0
            let b0 = isSourceBelow ? _b1 : _b0
            //
            let a1 = isSourceBelow ? _a0 : _a1
            let r1 = isSourceBelow ? _r0 : _r1
            let g1 = isSourceBelow ? _g0 : _g1
            let b1 = isSourceBelow ? _b0 : _b1
            //
            let a01 = (1.0 - a0) * a1 + a0
            let r01 = ((1.0 - a0) * a1 * r1 + a0 * r0) / a01
            let g01 = ((1.0 - a0) * a1 * g1 + a0 * g0) / a01
            let b01 = ((1.0 - a0) * a1 * b1 + a0 * b0) / a01
            //
            if !b01.isNaN {
                b0_Ptr.pointee = UInt8(b01 * 255.0)
            }
            if !g01.isNaN {
                g0_Ptr.pointee = UInt8(g01 * 255.0)
            }
            if !r01.isNaN {
                r0_Ptr.pointee = UInt8(r01 * 255.0)
            }
            if !a01.isNaN {
                a0_Ptr.pointee = UInt8(a01 * 255.0)
            }
        }
        return self
    }
    

    //    @objc func imageByAdding(_ image: FBImage?, at rect: CGRect, angle: CGFloat) -> FBImage {
    //        guard let image = image else {
    //            return self
    //        }
    //
    //        let scaleX = rect.size.width / image.size.width
    //        let scaleY = rect.size.height / image.size.height
    //        let transform = CGAffineTransform.identity
    //            .scaledBy(x: scaleX, y: scaleY)
    //            .translatedBy(x: rect.origin.x,
    //                          y: -rect.origin.y)
    //            .rotated(by: angle)
    //        let imageToAdd = image.imageByApplying(transform: transform)
    //
    //        let length = Int(self.imageBuffer.height) * self.imageBuffer.rowBytes
    //        let pixelCount = length / 4
    //
    //        let imageToAddBufferPointer = imageToAdd.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
    //        let destinationBufferPointer = self.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
    //
    //        for i in 0..<pixelCount {
    //            let pixelPointer = imageToAddBufferPointer + (i * 4)
    //            let _b = pixelPointer.pointee
    //            let _g = (pixelPointer + 1).pointee
    //            let _r = (pixelPointer + 2).pointee
    //            let _a = (pixelPointer + 3).pointee
    //            let sum = Int(_b) + Int(_g) + Int(_r) + Int(_a)
    //            if sum != 0 {
    //                let destinationPixelPointer = destinationBufferPointer + (i * 4)
    //                let b = destinationPixelPointer
    //                let g = (destinationPixelPointer + 1)
    //                let r = (destinationPixelPointer + 2)
    //                let a = (destinationPixelPointer + 3)
    //                b.pointee = _b
    //                g.pointee = _g
    //                r.pointee = _r
    //                a.pointee = _a
    //            }
    //        }
    //
    //        return self
    //    }
    
    private func maskImageFrom(path: UIBezierPath) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setAllowsAntialiasing(false)
        ctx?.interpolationQuality = .high
        
        UIColor.black.setFill()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func maskingWith(mask: FBImage, inverted: Bool) -> FBImage {
        let length = Int(self.imageBuffer.height) * self.imageBuffer.rowBytes
        let pixelCount = length / 4
        
        let imageBufferPointer = self.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)
        let maskBufferPointer = mask.imageBuffer.data.bindMemory(to: UInt8.self, capacity: length)

        for i in 0..<pixelCount {
            let pixelPointer = maskBufferPointer + (i * 4)
            let _b = pixelPointer.pointee
            let _g = (pixelPointer + 1).pointee
            let _r = (pixelPointer + 2).pointee
            let _a = (pixelPointer + 3).pointee
            let sum = Int(_b) + Int(_g) + Int(_r) + Int(_a)
            let isClear = sum == 0
            if (isClear && !inverted) || (!isClear && inverted) {
                let destinationPixelPointer = imageBufferPointer + (i * 4)
                let b = destinationPixelPointer
                let g = (destinationPixelPointer + 1)
                let r = (destinationPixelPointer + 2)
                let a = (destinationPixelPointer + 3)
                b.pointee = 0
                g.pointee = 0
                r.pointee = 0
                a.pointee = 0
            }
        }
        
        return self
    }
    
    @objc func imageByApplyingClippingBezierPath(_ path: UIBezierPath) -> FBImage {
        let mask = maskImageFrom(path: path)
        let fbmask = FBImage(premultipliedImage: mask)!
        return self.maskingWith(mask: fbmask, inverted: false)
    }

    @objc func imageByApplyingCuttingBezierPath(_ path: UIBezierPath) -> FBImage {
        let mask = maskImageFrom(path: path)
        let fbmask = FBImage(premultipliedImage: mask)!
        return self.maskingWith(mask: fbmask, inverted: true)
    }
    
}


extension Double {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}
