//
//  Canvas.swift
//  MaLiang
//
//  Created by Harley.xk on 2018/4/11.
//

import UIKit

open class Canvas: MetalView {
    
    // MARK: - Brushes
    
    /// default round point brush, will not show in registeredBrushes
    open var defaultBrush: Brush!
    
    /// Сlass for checking whether there is a connection to Apple Pencil
    private let pencilReachability = ApplePencilReachability()
    
    private var isStylusConnected: Bool { pencilReachability.isPencilAvailable }
    
    /// printer to print image textures on canvas
    open private(set) var printer: Printer!
    
    /// the actural size of canvas in points, may larger than current bounds
    /// size must between bounds size and 5120x5120
    @objc open var size: CGSize {
        return drawableSize
    }
    
    // delegate & observers
    
    open weak var renderingDelegate: RenderingDelegate?
    
    internal var actionObservers = ActionObserverPool()
    
    // add an observer to observe data changes, observers are not retained
    open func addObserver(_ observer: ActionObserver) {
        // pure nil objects
        actionObservers.clean()
        actionObservers.addObserver(observer)
    }
    
    /// Register a brush with image data
    ///
    /// - Parameter texture: texture data of brush
    /// - Returns: registered brush
    @discardableResult open func registerBrush<T: Brush>(name: String? = nil, from data: Data) throws -> T {
        let image = FBImage(premultipliedImage: UIImage(data: data)!)!
        let texture = try makeTexture(with: image)
        let brush = T(name: name, textureID: texture.id, target: self)
        registeredBrushes.append(brush)
        return brush
    }
    
    /// Register a brush with image data
    ///
    /// - Parameter file: texture file of brush
    /// - Returns: registered brush
    @discardableResult open func registerBrush<T: Brush>(name: String? = nil, from file: URL) throws -> T {
        let data = try Data(contentsOf: file)
        return try registerBrush(name: name, from: data)
    }
    
    /// Register a new brush with texture already registered on this canvas
    ///
    /// - Parameter textureID: id of a texture, default round texture will be used if sets to nil or texture id not found
    open func registerBrush<T: Brush>(name: String? = nil, textureID: String? = nil) throws -> T {
        let brush = T(name: name, textureID: textureID, target: self)
        registeredBrushes.append(brush)
        return brush
    }
    
    /// current brush used to draw
    /// only registered brushed can be set to current
    /// get a brush from registeredBrushes and call it's use() method to make it current
    open internal(set) var currentBrush: Brush!
    
    /// All registered brushes
    open private(set) var registeredBrushes: [Brush] = []
    
    /// find a brush by name
    /// nill will be retured if brush of name provided not exists
    open func findBrushBy(name: String?) -> Brush? {
        return registeredBrushes.first { $0.name == name }
    }
    
    /// All textures created by this canvas
    open private(set) var textures: [MLTexture] = []
    
    /// make texture and cache it with ID
    ///
    /// - Parameters:
    ///   - data: image data of texture
    ///   - id: id of texture, will be generated if not provided
    /// - Returns: created texture, if the id provided is already exists, the existing texture will be returend
    @discardableResult
    override func makeTexture(with image: FBImage, id: String? = nil) throws -> MLTexture {
        // if id is set, make sure this id is not already exists
        if let id = id, let exists = findTexture(by: id) {
            return exists
        }
        let texture = try super.makeTexture(with: image, id: id)
        textures.append(texture)
        return texture
    }
    
    /// Replace exiting texture by ID
    ///
    /// - Parameters:
    ///   - data: new image data of texture
    ///   - id: id of texture
    /// - Returns: created texture, if the id provided is already exists, the existing texture will be returend
    @discardableResult
    func replaceTexture(withNew image: FBImage, by id: String) throws -> MLTexture {
        // if id is set, make sure this id is not already exists
        guard let existing = findTexture(by: id) else {
            return try makeTexture(with: image, id: id)
        }
        let texture = try super.makeTexture(with: image, id: id)
        textures.removeAll(where: { $0 == existing })
        textures.append(texture)
        return texture
    }
    
    /// find texture by textureID
    open func findTexture(by id: String) -> MLTexture? {
        return textures.first { $0.id == id }
    }

    
    // MARK: - Zoom and scale
    /// the scale level of view, all things scales
    open var scale: CGFloat {
        get {
            return screenTarget?.scale ?? 1
        }
        set {
            screenTarget?.scale = newValue
        }
    }
    
    /// the zoom level of render target, only scale render target
    open var zoom: CGFloat {
        get {
            return screenTarget?.zoom ?? 1
        }
        set {
            screenTarget?.zoom = newValue
        }
    }
    
    /// the offset of render target with zoomed size
    open var contentOffset: CGPoint {
        get {
            return screenTarget?.contentOffset ?? .zero
        }
        set {
            screenTarget?.contentOffset = newValue
        }
    }
    
    
    /// this will setup the canvas and gestures、default brushs
    open override func setup() {
        super.setup()
        
        /// initialize default brush
        defaultBrush = Brush(name: "maliang.default", textureID: nil, target: self)
        currentBrush = defaultBrush
        
        /// initialize printer
        printer = Printer(name: "maliang.printer", textureID: nil, target: self)
        
        data = CanvasData()
    }
    
    /// take a snapshot on current canvas and export an image
    func snapshot() -> FBImage? {
        return screenTarget?.getImage()
    }
    
    /// clear all things on the canvas
    ///
    /// - Parameter display: redraw the canvas if this sets to true
    open override func clear(display: Bool = true) {
        super.clear(display: display)
        
        if display {
            data.appendClearAction()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        redraw()
    }
    
    // MARK: - Document
    public private(set) var data: CanvasData!
    
    /// reset data on canvas, this method will drop the old data object and create a new one.
    /// - Attention: SAVE your data before call this method!
    /// - Parameter redraw: if should redraw the canvas after, defaults to true
    open func resetData(redraw: Bool = true) {
        let oldData = data!
        let newData = CanvasData()
        // link registered observers to new data
        newData.observers = data.observers
        data = newData
        if redraw {
            self.redraw()
        }
        data.observers.data(oldData, didResetTo: newData)
    }
    
    public func undo() {
        if let data = data, data.undo() {
            redraw()
        }
    }
    
    public func redo() {
        if let data = data, data.redo() {
            redraw()
        }
    }
    
    /// redraw elemets in document
    /// - Attention: thie method must be called on main thread
    open func redraw(on target: RenderTarget? = nil) {
        guard let target = target ?? screenTarget else {
            return
        }
        
        data.finishCurrentElement()
        
        target.updateBuffer(with: drawableSize)
        target.clear()

        data.elements.forEach { $0.drawSelf(on: target) }
        
        /// submit commands
        target.commitCommands()
        
        actionObservers.canvas(self, didRedrawOn: target)
    }
    
    // MARK: - Bezier
    // optimize stroke with bezier path, defaults to true
    //    private var enableBezierPath = true
    private var bezierGenerator = BezierGenerator()
    
    // MARK: - Drawing Actions
    private var lastRenderedPan: Pan?
    
    private func pushPoint(_ point: CGPoint, to bezier: BezierGenerator, force: CGFloat, isEnd: Bool = false) {
        var lines: [MLLine] = []
        let vertices = bezier.pushPoint(point)
        guard vertices.count >= 2 else {
            return
        }
        var lastPan = lastRenderedPan ?? Pan(point: vertices[0], force: force)
        let deltaForce = (force - (lastRenderedPan?.force ?? force)) / CGFloat(vertices.count)
        for i in 1 ..< vertices.count {
            let p = vertices[i]
            let pointStep = currentBrush.pointStep
            if  // end point of line
                (isEnd && i == vertices.count - 1) ||
                    // ignore step
                    pointStep <= 1 ||
                    // distance larger than step
                    (pointStep > 1 && lastPan.point.distance(to: p) >= pointStep)
            {
                let force = lastPan.force + deltaForce
                let pan = Pan(point: p, force: force)
                let line = currentBrush.makeLine(from: lastPan, to: pan, hardness: self.hardness)
                lines.append(contentsOf: line)
                lastPan = pan
                lastRenderedPan = pan
            }
        }
        render(lines: lines)
    }
    
    // MARK: - Rendering
    
    open func render(lines: [MLLine]) {
        data.append(lines: lines, with: currentBrush)
        // create a temporary line strip and draw it on canvas
        LineStrip(lines: lines, brush: currentBrush).drawSelf(on: screenTarget)
        /// submit commands
        screenTarget?.commitCommands()
    }
    
    open func renderTap(at point: CGPoint, to: CGPoint? = nil) {
        guard renderingDelegate?.canvas(self, shouldRenderTapAt: point) ?? true else {
            return
        }
        
        let brush = currentBrush!
        let lines = brush.makeLine(from: point, to: to ?? point, hardness: 0.5)
        render(lines: lines)
    }
    
    /// draw a chartlet to canvas
    ///
    /// - Parameters:
    ///   - point: location where to draw the chartlet
    ///   - size: size of texture
    ///   - textureID: id of texture for drawing
    ///   - rotation: rotation angle of texture for drawing
    open func renderChartlet(at point: CGPoint, size: CGSize, textureID: String, rotation: CGFloat = 0) {
        
        let chartlet = Chartlet(center: point, size: size, textureID: textureID, angle: rotation, canvas: self)
        
        guard renderingDelegate?.canvas(self, shouldRenderChartlet: chartlet) ?? true else {
            return
        }
        
        data.append(chartlet: chartlet)
        chartlet.drawSelf(on: screenTarget)
        screenTarget?.commitCommands()
        setNeedsDisplay()
        
        actionObservers.canvas(self, didRenderChartlet: chartlet)
    }
    
    // MARK: - Touches
    
    private var oldSpeed: CGFloat = 0.0
    private var oldLocation: CGPoint?
    private var oldTimestamp: TimeInterval = 0
    
    private var pressureSensitivity: CGFloat = 5.0 // 1..10
    var hardness: CGFloat = 5.0 // 1..10
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let basePressureSensitivity: CGFloat = Stylus.shared.basePressureSensitivity
        pressureSensitivity = (UserDefaults.standard.double(forKey: kBrushPressureSensitivityKey) + basePressureSensitivity) / (10.0 + basePressureSensitivity)
        
        let baseHardness: CGFloat = 3.0
        hardness = (UserDefaults.standard.double(forKey: kBrushSmoothingKey) + baseHardness) / (10.0 + baseHardness)
        
        guard let touch = touches.first else {
            return
        }
        
        let pan = Pan(point: touch.location(in: self), force: touch.type == .pencil ? 0 : isStylusConnected ? 0.0 : 0.0)
        lastRenderedPan = pan
        
        guard renderingDelegate?.canvas(self, shouldBeginLineAt: pan.point, force: pan.force) ?? true else {
            return
        }
        
        bezierGenerator.begin(with: pan.point)
        pushPoint(pan.point, to: bezierGenerator, force: pan.force)
        actionObservers.canvas(self, didBeginLineAt: pan.point, force: pan.force)
    }
        
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard bezierGenerator.points.count > 0 else { return }
        guard let touch = touches.first else {
            return
        }
                
        guard touch.location(in: self) != lastRenderedPan?.point else {
            return
        }
        let location = touch.location(in: self)
        let timestamp = touch.timestamp
        
        let brushName: String = ((UserDefaults.standard.object(forKey: kCurrentBrushPrefKey) as? String?) ?? currentBrush.name) ?? ""
        
        let minWidth = UserDefaults.standard.minPressureWidth(for: brushName)
        let maxWidth = UserDefaults.standard.maxPressureWidth(for: brushName)/2
        
        var force: CGFloat
        if touch.type == .direct {
                        
            if isStylusConnected {
                
                let lambda: CGFloat = Stylus.shared.lambda // the closer to 1 the higher weight to the next touch
                let distanceFromPrevious = oldLocation?.distance(to: location) ?? 0.0
                let timeSincePrevious = CGFloat(timestamp - oldTimestamp)
                let fst = (1.0 - lambda) * oldSpeed
                let snd = lambda * (distanceFromPrevious / timeSincePrevious)
                let newSpeed = fst + snd
                oldSpeed = newSpeed
                oldLocation = location
                oldTimestamp = timestamp
                let MAX_SPEED: CGFloat = 1000.0
                force = newSpeed / MAX_SPEED

                let offset = minWidth / maxWidth
                let multiplier = 1.0 - offset
                
                force = (force * multiplier) + offset

            } else {
                let lambda: CGFloat = 0.2// the closer to 1 the higher weight to the next touch
                let distanceFromPrevious = oldLocation?.distance(to: location) ?? 0.0
                let timeSincePrevious = CGFloat(timestamp - oldTimestamp)
                let fst = (1.0 - lambda) * oldSpeed
                let snd = lambda * (distanceFromPrevious / timeSincePrevious)
                let newSpeed = fst + snd
                oldSpeed = newSpeed
                oldLocation = location
                oldTimestamp = timestamp
                let MAX_SPEED: CGFloat = (1 + pressureSensitivity)*1000
                force = newSpeed / MAX_SPEED
                let offset = minWidth / maxWidth
                let multiplier = 1.0 - offset
                force = (force * multiplier) + offset
            }
            
        } else {
            let average = Stylus.shared.average
            //pressinigforce = ((1.612903225 - pressureSensitivity) * (touch.force + average)) / (touch.maximumPossibleForce - average)
            force = ((pressureSensitivity + 0.27956985) * (touch.force + average)) / (touch.maximumPossibleForce - average)
            print("pressing value = \(pressureSensitivity), touch = \(touch.force), force = \(force)")
        }
        if force < 0.0 {
            force = 0.0
        }
        if force > 1.0 {
            force = 1.0
        }
        
        /*
                 
        If you comment out these lines then the line with min == 1 and max == 1 and the line with light pressure are the same.
        This code was moved to line 382.
         
        let offset = minWidth / maxWidth
        let multiplier = (1.0 - offset)
        force = (force * multiplier) + offset
         
         */
        
        let pan = Pan(point: location, force: force)
        
        pushPoint(pan.point, to: bezierGenerator, force: pan.force)
        actionObservers.canvas(self, didMoveLineTo: pan.point, force: pan.force)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            bezierGenerator.finish()
            lastRenderedPan = nil
            data.finishCurrentElement()
        }

        guard let touch = touches.first else {
            return
        }

        let lastLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        
        let pan: Pan
        if lastLocation.distance(to: previousLocation) > CGFloat(kMaxBrushSize) {
            let midLocation = CGPoint.middle(p1: lastLocation, p2: previousLocation)
            pan = Pan(point: midLocation, force: 0.0)
        } else {
            pan = Pan(point: lastLocation, force: 0.0)
        }

        let count = bezierGenerator.points.count
        if count >= 3 {
            pushPoint(pan.point, to: bezierGenerator, force: pan.force, isEnd: true)
        } else if count > 0 {
            renderTap(at: bezierGenerator.points.first!, to: bezierGenerator.points.last!)
        }
        
        let unfishedLines = currentBrush.finishLineStrip(at: Pan(point: pan.point, force: pan.force))
        if unfishedLines.count > 0 {
            render(lines: unfishedLines)
        }
        actionObservers.canvas(self, didFinishLineAt: pan.point, force: pan.force)
    }
    
}

extension UserDefaults {
    
    func minPressureWidth(for brushName: String) -> CGFloat {
        let dict = object(forKey: kMinimumLineWidthsPrefKey) as? [String: NSNumber]
        return CGFloat(dict?[brushName]?.floatValue ?? kMinBrushSize)
    }
    
    func maxPressureWidth(for brushName: String) -> CGFloat {
        let dict = object(forKey: kMaximumLineWidthsPrefKey) as? [String: NSNumber]
        return CGFloat(dict?[brushName]?.floatValue ?? kMaxBrushSize)
    }
}
