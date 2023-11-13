//
//  RenderTarget.swift
//  MaLiang
//
//  Created by Harley-xk on 2019/4/15.
//

import UIKit
import Foundation
import Metal
import MetalKit
import simd

/// a target for any thing that can be render on
open class RenderTarget {
    
    /// texture to render on
    public private(set) var texture: MTLTexture?
    
    /// the scale level of view, all things scales
    open var scale: CGFloat = 1 {
        didSet {
            updateTransformBuffer()
        }
    }
    
    /// the zoom level of render target, only scale render target
    open var zoom: CGFloat = 1

    /// the offset of render target with zoomed size
    open var contentOffset: CGPoint = .zero {
        didSet {
            updateTransformBuffer()
        }
    }
    
    /// create with texture and device
    public init(size: CGSize, pixelFormat: MTLPixelFormat, device: MTLDevice?) {
        self.drawableSize = size
        self.pixelFormat = pixelFormat
        self.device = device
        self.commandQueue = device?.makeCommandQueue()
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        
        UIGraphicsBeginImageContext(drawableSize)
        let context = UIGraphicsGetCurrentContext()
        clearCgImage = context!.makeImage()!
        UIGraphicsEndImageContext()
        
        self.texture = makeEmptyTexture()
        
        let attachment = renderPassDescriptor?.colorAttachments[0]
        attachment?.texture = texture
        attachment?.loadAction = .load
        attachment?.storeAction = .store
        
        updateBuffer(with: size)
    }
    
    func getImage() -> FBImage? {
        guard let device = device else { return nil }
        
        commitCommands()
        
    #if targetEnvironment(macCatalyst)
        let hasUnifiedMemory = device.hasUnifiedMemory
        if hasUnifiedMemory {
            return texture?.toFBImage()
        } else {
            guard let texture = texture else {
                print("🔥 No device or texture")
                return nil
            }
                    
            guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
                print("🔥 Could not create new command buffer")
                return nil
            }
            
            let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
            blitCommandEncoder?.synchronize(resource: texture)
            blitCommandEncoder?.endEncoding()
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            return texture.toFBImage()
        }
    #else
        return texture?.toFBImage()
    #endif
    }
    
    /// clear the contents of texture
    open func clear() {
        texture = makeEmptyTexture()
        renderPassDescriptor?.colorAttachments[0].texture = texture
    }
    
    internal var pixelFormat: MTLPixelFormat = .bgra8Unorm
    internal var drawableSize: CGSize {
        didSet {
            updateClearCgImage()
        }
    }
    internal var uniform_buffer: MTLBuffer!
    internal var transform_buffer: MTLBuffer!
    internal var renderPassDescriptor: MTLRenderPassDescriptor?
    internal var commandBuffer: MTLCommandBuffer?
    internal var commandQueue: MTLCommandQueue?
    internal var device: MTLDevice?
    
    internal func updateBuffer(with size: CGSize) {
        self.drawableSize = size
        let metrix = Matrix.identity
        let zoomUniform = 2 * Float(zoom / scale )
        metrix.scaling(x: zoomUniform  / Float(size.width), y: -zoomUniform / Float(size.height), z: 1)
        metrix.translation(x: -1, y: 1, z: 0)
        uniform_buffer = device?.makeBuffer(bytes: metrix.m, length: MemoryLayout<Float>.size * 16, options: [])
        
        updateTransformBuffer()
    }
    
    internal func updateTransformBuffer() {
        let scaleFactor = UIScreen.main.nativeScale
        var transform = ScrollingTransform(offset: contentOffset * scaleFactor, scale: scale)
        transform_buffer = device?.makeBuffer(bytes: &transform, length: MemoryLayout<ScrollingTransform>.stride, options: [])
    }
    
    internal func prepareForDraw() {
        if commandBuffer == nil {
            commandBuffer = commandQueue?.makeCommandBuffer()
        }
    }

    internal func makeCommandEncoder() -> MTLRenderCommandEncoder? {
        guard let commandBuffer = commandBuffer, let rpd = renderPassDescriptor else {
            return nil
        }
        return commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
    }
        
    internal func commitCommands() {
        commandBuffer?.commit()
        commandBuffer = nil
    }
    
    private var clearCgImage: CGImage
    
    private func updateClearCgImage() {
        UIGraphicsBeginImageContext(drawableSize)
        let context = UIGraphicsGetCurrentContext()
        clearCgImage = context!.makeImage()!
        UIGraphicsEndImageContext()
    }
    
    // make empty testure
    internal func makeEmptyTexture() -> MTLTexture? {
        guard let device = device, drawableSize.width * drawableSize.height > 0 else {
            return nil
        }
        var options: [MTKTextureLoader.Option: Any] = [.SRGB: false]
        let usage: MTLTextureUsage = [.renderTarget, .shaderRead]
        options[.textureUsage] = NSNumber(value: usage.rawValue)
            
    #if targetEnvironment(macCatalyst)
        if !device.hasUnifiedMemory {
            options[.textureStorageMode] = NSNumber(value: MTLStorageMode.managed.rawValue)
        }
    #endif
        
        let texture = try? MTKTextureLoader(device: device).newTexture(cgImage: clearCgImage, options: options)
        return texture
    }
    
}
