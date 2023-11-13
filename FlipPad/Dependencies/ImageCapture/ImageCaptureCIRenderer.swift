//
//  ImageCaptureCIRenderer.swift
//  AVCamFilter
//
//  Created by Alex Vihlayew on 9/21/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import CoreMedia
import CoreVideo
import CoreImage

class ImageCaptureCIRenderer: FilterRenderer {
    
    var isEnabled: Bool = true
    
    var description: String = "ImageCapture (Core Image)"
    
    var isPrepared = false
    
    private var ciContext: CIContext?
    
    private var filterGamma: CIFilter?
    private var filterColorEnhance: CIFilter?
    private var filterConvolution: CIFilter?
    private var pencilFilter: CIFilter?
    
    private var outputColorSpace: CGColorSpace?
    
    private var outputPixelBufferPool: CVPixelBufferPool?
    
    private(set) var outputFormatDescription: CMFormatDescription?
    
    private(set) var inputFormatDescription: CMFormatDescription?
    
    func setupFilters() {
        let multiplier: CGFloat = 2.0
        let convolutionValue_A: CGFloat = -0.0925937220454216 * multiplier
        let convolutionValue_B: CGFloat = -0.4166666567325592 * multiplier
        let convolutionValue_C: CGFloat = -1.8518532514572144 * multiplier
        let convolutionValue_D: CGFloat = 0.23148006200790405 * multiplier
        let convolutionValue_E: CGFloat = 4.5833334922790527 * multiplier
        let convolutionValue_F: CGFloat = 14.166666984558105 * multiplier
        
        let brightnessVal: CGFloat = 1.1041666269302368
        let contrastVal: CGFloat = 3.0555555820465088

        let weightsArr: [CGFloat] = [
            convolutionValue_A, convolutionValue_A, convolutionValue_B, convolutionValue_B, convolutionValue_B, convolutionValue_A, convolutionValue_A,
            convolutionValue_A, convolutionValue_B, convolutionValue_C, convolutionValue_C, convolutionValue_C, convolutionValue_B, convolutionValue_A,
            convolutionValue_B, convolutionValue_C, convolutionValue_D, convolutionValue_E, convolutionValue_D, convolutionValue_C, convolutionValue_B,
            convolutionValue_B, convolutionValue_C, convolutionValue_E, convolutionValue_F, convolutionValue_E, convolutionValue_C, convolutionValue_B,
            convolutionValue_B, convolutionValue_C, convolutionValue_D, convolutionValue_E, convolutionValue_D, convolutionValue_C, convolutionValue_B,
            convolutionValue_A, convolutionValue_B, convolutionValue_C, convolutionValue_C, convolutionValue_C, convolutionValue_B, convolutionValue_A,
            convolutionValue_A, convolutionValue_A, convolutionValue_B, convolutionValue_B, convolutionValue_B, convolutionValue_A, convolutionValue_A
        ]

        let inputWeights: CIVector = CIVector(values: weightsArr, count: weightsArr.count)

        let maxGamma: Float = 3.0 - 0.01
        let gamma = 0.01 + ((UserDefaults.standard.value(forKey: kCaptureGammaKey) as? Float) ?? 50.0) / 100.0 * maxGamma
        self.filterGamma = CIFilter(name: "CIGammaAdjust", parameters: ["inputPower": NSNumber(value: gamma)])
        
        self.filterColorEnhance = CIFilter(name: "CIColorControls", parameters: [kCIInputSaturationKey: 0.0,
                                                                      kCIInputBrightnessKey: brightnessVal,
                                                                      kCIInputContrastKey: contrastVal])
        
        self.filterConvolution = CIFilter(name: "CIConvolution7X7", parameters: [kCIInputWeightsKey: inputWeights])
        
        if #available(iOS 11.0, *) {
            self.pencilFilter = PencilFilter()
        }
    }
    
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()
        
        (outputPixelBufferPool,
         outputColorSpace,
         outputFormatDescription) = allocateOutputBufferPool(with: formatDescription,
                                                             outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        ciContext = CIContext()
        
        self.setupFilters()
        
        isPrepared = true
    }
    
    func reset() {
        ciContext = nil
        filterGamma = nil
        filterColorEnhance = nil
        filterConvolution = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard isEnabled else {
            return pixelBuffer
        }
        
        guard let ciContext = ciContext, isPrepared else {
            assertionFailure("Invalid state: Not prepared")
            return nil
        }
        
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        
        filterGamma!.setValue(sourceImage, forKey: kCIInputImageKey)
        let resultImageGamma = filterGamma!.value(forKey: kCIOutputImageKey) as! CIImage
        
        filterColorEnhance!.setValue(resultImageGamma, forKey: kCIInputImageKey)
        let resultImageColorEnhance = filterColorEnhance!.value(forKey: kCIOutputImageKey) as! CIImage
        
        filterConvolution!.setValue(resultImageColorEnhance, forKey: kCIInputImageKey)
        let resultImageConvolution = filterConvolution!.value(forKey: kCIOutputImageKey) as! CIImage
        
        var resultPencilImage: CIImage
        
        if #available(iOS 11.0, *) {
            let pencilFilter = pencilFilter as! PencilFilter
            pencilFilter.pencilThreshold = ((UserDefaults.standard.value(forKey: kCaptureWhiteKey) as? Float) ?? 50.0) / 100.0
            pencilFilter.inputImage = resultImageConvolution
            resultPencilImage = pencilFilter.outputImage!.cropped(to: sourceImage.extent)
        } else {
            resultPencilImage = resultImageConvolution
        }
        
        
        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }
        
        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(resultPencilImage, to: outputPixelBuffer, bounds: sourceImage.extent, colorSpace: outputColorSpace)
        return outputPixelBuffer
    }
    
}

