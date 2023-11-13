//
//  PencilFilter.swift
//  PencilFilter
//
//  Created by Alex Vihlayew on 9/23/21.
//  Copyright © 2021 Alex. All rights reserved.
//

@available(iOS 11.0, *)
class PencilFilter: CIFilter {
    
    private let kernel: CIColorKernel
    
    var pencilThreshold: Float = 0.8
    var inputImage: CIImage? // (1)
    
    override init() {
        kernel = CIColorKernel(source: "kernel vec4 thresholdFilter(__sample image, float thresholdLuma)" +
                                        "{" +
                                        "   float imageLuma = (image.r + image.g + image.b) / 3.0;" +
                                        "   if (thresholdLuma > imageLuma) {" +
                                        "       return vec4(0.0, 0.0, 0.0, 1.0);" +
                                        "   } else {" +
                                        "       return vec4(0.0, 0.0, 0.0, 0.0);" +
                                        "   }" +
                                        "}"
        )!
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        guard let inputImage = self.inputImage else { return nil }
        
        let inputExtent = inputImage.extent

        print(pencilThreshold)
        return self.kernel.apply(extent: inputExtent, arguments: [inputImage, pencilThreshold])  // (5)
    }
}
