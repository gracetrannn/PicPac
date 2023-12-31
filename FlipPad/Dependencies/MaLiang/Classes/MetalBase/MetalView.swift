//
//  MetalView.swift
//  MaLiang_Example
//
//  Created by Harley-xk on 2019/4/3.
//  Copyright © 2019 Harley-xk. All rights reserved.
//

import UIKit
import QuartzCore
import MetalKit
import Accelerate

internal let sharedDevice = { () -> MTLDevice? in
    return MTLCreateSystemDefaultDevice()
}()

public enum MetalViewError: Error {
    
    case noDevice
    case cgImageIsNil
}

open class MetalView: MTKView {
    
    // MARK: - Brush Textures
    
    func makeTexture(with image: FBImage, id: String? = nil) throws -> MLTexture {
        guard let device = device ?? sharedDevice else {
            throw MetalViewError.noDevice
        }
        let cgImage = image.cgImage
        let textureLoader = MTKTextureLoader(device: device)
        var options: [MTKTextureLoader.Option: Any] = [.SRGB: false]
#if targetEnvironment(macCatalyst)
        if !device.hasUnifiedMemory {
            options[.textureStorageMode] = NSNumber(value: MTLStorageMode.managed.rawValue)
        }
#endif
        let texture = try textureLoader.newTexture(cgImage: cgImage, options: options)
        return MLTexture(id: id ?? UUID().uuidString, texture: texture)
    }
    
//    func makeTexture(with file: URL, id: String? = nil) throws -> MLTexture {
//        let data = try Data(contentsOf: file)
//        return try makeTexture(with: data, id: id)
//    }
    
    // MARK: - Functions
    // Erases the screen, redisplay the buffer if display sets to true
    open func clear(display: Bool = true) {
        screenTarget?.clear()
        if display {
            setNeedsDisplay()
        }
    }

    // MARK: - Render
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        screenTarget?.updateBuffer(with: drawableSize)
    }

    open override var backgroundColor: UIColor? {
        didSet {
            clearColor = (backgroundColor ?? .white).toClearColor()
        }
    }

    // MARK: - Setup
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    open func setup() {
        device = sharedDevice
        isOpaque = false

        autoResizeDrawable = false
        drawableSize = self.frame.size
        
        presentsWithTransaction = true
        
        screenTarget = RenderTarget(size: drawableSize, pixelFormat: colorPixelFormat, device: device)
        commandQueue = device?.makeCommandQueue()

        setupTargetUniforms()

        do {
            try setupPiplineState()
        } catch {
            fatalError("Metal initialize failed: \(error.localizedDescription)")
        }
    }

    // pipeline state
    
    private var pipelineState: MTLRenderPipelineState!

    private func setupPiplineState() throws {
        let library = device?.libraryForMaLiang()
        let vertex_func = library?.makeFunction(name: "vertex_render_target")
        let fragment_func = library?.makeFunction(name: "fragment_render_target")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = colorPixelFormat
        //
//        rpd.colorAttachments[0].isBlendingEnabled = true
//        rpd.colorAttachments[0].alphaBlendOperation = .add
//        rpd.colorAttachments[0].rgbBlendOperation = .add
//        rpd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
//        rpd.colorAttachments[0].sourceAlphaBlendFactor = .one
//        rpd.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
//        rpd.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        //
        pipelineState = try device?.makeRenderPipelineState(descriptor: rpd)
    }

    // render target for rendering contents to screen
    internal var screenTarget: RenderTarget?
    
    private var commandQueue: MTLCommandQueue?

    // Uniform buffers
    private var render_target_vertex: MTLBuffer!
    private var render_target_uniform: MTLBuffer!
    
    func setupTargetUniforms() {
        let size = drawableSize
        let w = size.width, h = size.height
        let vertices = [
            Vertex(position: CGPoint(x: 0 , y: 0), textCoord: CGPoint(x: 0, y: 0)),
            Vertex(position: CGPoint(x: w , y: 0), textCoord: CGPoint(x: 1, y: 0)),
            Vertex(position: CGPoint(x: 0 , y: h), textCoord: CGPoint(x: 0, y: 1)),
            Vertex(position: CGPoint(x: w , y: h), textCoord: CGPoint(x: 1, y: 1)),
        ]
        render_target_vertex = device?.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: .cpuCacheModeWriteCombined)
        
        let metrix = Matrix.identity
        metrix.scaling(x: 2 / Float(size.width), y: -2 / Float(size.height), z: 1)
        metrix.translation(x: -1, y: 1, z: 0)
        render_target_uniform = device?.makeBuffer(bytes: metrix.m, length: MemoryLayout<Float>.size * 16, options: [])
    }
        
    var renderCompletion: (() -> Void)? = nil
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
                
        guard let texture = screenTarget?.texture, let drawable = currentDrawable else {
            return
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment = renderPassDescriptor.colorAttachments[0]
        attachment?.clearColor = clearColor
        attachment?.texture = currentDrawable?.texture
        attachment?.loadAction = .clear
        attachment?.storeAction = .store
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        commandEncoder?.setRenderPipelineState(pipelineState)
        
        commandEncoder?.setVertexBuffer(render_target_vertex, offset: 0, index: 0)
        commandEncoder?.setVertexBuffer(render_target_uniform, offset: 0, index: 1)
        commandEncoder?.setFragmentTexture(texture, index: 0)
        commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder?.endEncoding()
        
        if let renderCompletion = renderCompletion {
            commandBuffer?.addCompletedHandler({ _ in
                renderCompletion()
            })
            self.renderCompletion = nil
        }
        
        commandBuffer?.commit()
        commandBuffer?.waitUntilScheduled()
        
        drawable.present()
    }
}
