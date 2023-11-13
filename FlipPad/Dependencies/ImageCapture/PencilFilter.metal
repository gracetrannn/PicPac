//
//  PencilFilter.metal
//  PencilFilter
//
//  Created by Alex Vihlayew on 9/23/21.
//  Copyright © 2021 Alex. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h> // (1)

extern "C" { namespace coreimage {               // (3)
    
    float4 pencilFilter(sample_t pixelColor, float threshold) {
        
        float luminance = (pixelColor.r + pixelColor.g + pixelColor.b) / 3.0;

        if (luminance < threshold) {
            return float4(0.0, 0.0, 0.0, 0.0); // Transparent
        } else {
            return float4(0.0, 0.0, 0.0, 1.0); // Black
        }
    }
    
}}
