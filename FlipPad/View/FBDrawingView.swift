//
//  FBDrawingView.swift
//  FlipPad
//
//  Created by Alex on 17.12.2019.
//  Copyright © 2019 DigiCel, Inc. All rights reserved.
//

import UIKit
import CoreGraphics

@objc protocol FBSketchViewDelegate: AnyObject {
    
    func update(pencilImage: FBImage?, structureImage: FBImage?, fillImage: FBImage?)
        
    func refreshCellPreview(image: FBImage?)
    
    func didPauseOn(row: Int)
    
    func selectNextRowWithContent()
    
    func fillLevelCells(onlyCurrentCell: Bool)
}

enum Command {
    case stroke(FBImage?)
    case fill(FBImage?)
    case fillCell(FBImage?)
    case cutAndPaste(FBImage?, FBImage?, FBImage?) // Pencil, Fill, Structure, Canvas strokes
}

@objc class DrawingCommand: NSObject {
    var type: Command
    
    let timestamp: TimeInterval
    
    init(type: Command, timestamp: TimeInterval? = nil) {
        self.type = type
        self.timestamp = timestamp ?? ProcessInfo().systemUptime
    }
}

let kPencilChartletID = "PencilChartletID"
let kClearChartletID = "ClearChartletID"

class FBDrawingView: Canvas {

    var startPoint = CGPoint()
    var endPointPoint = CGPoint()
    var isStarted = false
    var shapeLayer = CAShapeLayer()
    
    func drawLine(onLayer layer: CALayer, fromPoint start: CGPoint, toPoint end: CGPoint) {
        
        let previousSelection: String = UserDefaults.standard.string(forKey: kCurrentShapePrefKey) ?? ""

        if (previousSelection == "Line" || previousSelection == "Multilines") && !isEraserTool && !isFillTool{
            if isStarted {
                strokeFinished()
                undoManager?.undo()
            }
            
            var lines: [MLLine] = []
            let line = currentBrush.makeLine(from: start, to: end, hardness: self.hardness)
            lines.append(contentsOf: line)

            render(lines: lines)
        } else if previousSelection == "Square" && !isEraserTool {
            if isStarted {
                strokeFinished()
                undoManager?.undo()
            }
            
            var lines: [MLLine] = []
            
            let line1StartPoint = CGPoint.init(x: start.x, y: start.y)
            let line1EndPoint = CGPoint.init(x: end.x, y: start.y)

            let line2StartPoint = CGPoint.init(x: start.x, y: start.y)
            let line2EndPoint = CGPoint.init(x: start.x, y: end.y)
            
            let line3StartPoint = CGPoint.init(x: end.x, y: start.y)
            let line3EndPoint = CGPoint.init(x: end.x, y: end.y)

            let line4StartPoint = CGPoint.init(x: start.x, y: end.y)
            let line4EndPoint = CGPoint.init(x: end.x, y: end.y)

            
            
            let line1 = currentBrush.makeLine(from: line1StartPoint, to: line1EndPoint, hardness: self.hardness)
            let line2 = currentBrush.makeLine(from: line2StartPoint, to: line2EndPoint, hardness: self.hardness)
            let line3 = currentBrush.makeLine(from: line3StartPoint, to: line3EndPoint, hardness: self.hardness)
            let line4 = currentBrush.makeLine(from: line4StartPoint, to: line4EndPoint, hardness: self.hardness)

            lines.append(contentsOf: line1)
            lines.append(contentsOf: line2)
            lines.append(contentsOf: line3)
            lines.append(contentsOf: line4)

            render(lines: lines)
        } else if previousSelection == "Circle" && !isEraserTool {
            if isStarted {
                strokeFinished()
                undoManager?.undo()
            }
            
            let middleX = end.x - ((end.x - start.x)/2)
            let middleY = end.y - ((end.y - start.y)/2)
            
            let middlePoint = CGPoint.init(x: middleX, y: middleY)

//            let centerDot = currentBrush.makeLine(from: middlePoint, to: middlePoint, hardness: self.hardness)

            let radius = distance(middlePoint, end)

            let circumference = 2 * CGFloat.pi * radius
            
            let parts = circumference/hardness
            
//            let n = (parts < 1) ? 1.0 : ((parts > 360) ? 360 : parts)
            let n = (parts < 1) ? 1.0 : parts

            
//            let points = getCirclePoints(centerPoint: middlePoint, radius: radius, n: Int(n))
            let points = getCirclePoints(centerPoint: middlePoint, radius: radius, n: Int(n))

            
            print("points: \(points)")
            
            var lines: [MLLine] = []
            
            for point in points {
                let pointDot = currentBrush.makeLine(from: point, to: point, hardness: self.hardness)
                lines.append(contentsOf: pointDot)
            }
            
            render(lines: lines)
            
            
            
//            let circlePath = UIBezierPath(arcCenter: CGPoint(x: 100, y: 100), radius: CGFloat(20), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
//
//            let shapeLayer = CAShapeLayer()
//            shapeLayer.path = circlePath.cgPath
//
//            // Change the fill color
//            shapeLayer.fillColor = UIColor.clear.cgColor
//            // You can change the stroke color
//            shapeLayer.strokeColor = UIColor.red.cgColor
//            // You can change the line width
//            shapeLayer.lineWidth = 3.0
//
//            layer.addSublayer(shapeLayer)
        }
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
//    func getCirclePoints(centerPoint point: CGPoint, radius: CGFloat, n: Int)->[CGPoint] {
//        let result: [CGPoint] = stride(from: 0.0, to: 360.0, by: Double(360 / n)).map {
//            let bearing = CGFloat($0) * .pi / 180
//            let x = point.x + radius * cos(bearing)
//            let y = point.y + radius * sin(bearing)
//            return CGPoint(x: x, y: y)
//        }
//        return result
//    }
    
    func getCirclePoints(centerPoint point: CGPoint, radius: CGFloat, n: Int) -> [CGPoint] {
        return Array(repeating: 0, count: n).enumerated().map { offset, element in
            let cgFloatIndex = CGFloat(offset)
            let radiansStep = CGFloat.pi * CGFloat(2.0) / CGFloat(n)
            let radians = radiansStep * cgFloatIndex
            let x = cos(radians) * radius + point.x
            let y = sin(radians) * radius + point.y
            return CGPoint(x: x, y: y)
        }
    }
    
    @objc weak var drawingDelegate: FBSketchViewDelegate?
    @objc weak var sceneController: FBSceneController?
    
    @objc var isTouchEnabled: Bool = true
    
    // Sublayers
    
    let backgroundLayer = CALayer()
    let fillLayer = CALayer()
    let compositedLayer = CALayer()
    let lightboxLayer = CALayer()
    
    private let isDebug = false
    
#if DEBUG
    
    let debugLayer = CALayer()
    
#endif
    
    // Current images
    
    var currentPencilImage: FBImage?
    var currentFillImage: FBImage?
    var currentStructureImage: FBImage?
    var currentBackgroundImage: FBImage?
    
    var currentLightboxImage: UIImage?
    var currentCompositedImage: UIImage?
    
    var currentPlaybackImages: [CGImage?]?
    
    //
    
    var prefUsingFillTool: Bool = false
    var fillMode: FBFillMode {
        return sceneController?.fillMode ?? .normal
    }
    private var brush: Brush?
    
    // Undo / Redo support
    
    private let _undoManager = { () -> UndoManager in
        let manager = UndoManager()
        manager.levelsOfUndo = Int(kMaxUndoHistory)
        return manager
    }()
    override var undoManager: UndoManager? {
        return _undoManager
    }
    private var lastCommand: DrawingCommand?
    
    @objc func undoDrawing(_ command: DrawingCommand) {
        var newCommand: DrawingCommand?
        
        switch command.type {
        case .stroke(let previousStrokeImage):
            print("⬅️ Undo stroke")
            newCommand = DrawingCommand(type: .stroke(currentStructureImage), timestamp: command.timestamp)
            currentStructureImage = previousStrokeImage
            self.undo()
            redraw()
        case .fill(let previousFillImage):
            print("⬅️ Undo fill")
            newCommand = DrawingCommand(type: .fill(currentFillImage), timestamp: command.timestamp)
            currentFillImage = previousFillImage
            redraw()
        case .fillCell(let previousFillImage):
            print("⬅️ Undo autofill cell")
            newCommand = DrawingCommand(type: .fillCell(currentFillImage), timestamp: command.timestamp)
            currentFillImage = previousFillImage
            redraw()
        case .cutAndPaste(let pencilImage, let fillImage, let structureImage):
            print("⬅️ Undo cut & paste")
            newCommand = DrawingCommand(type: .cutAndPaste(currentPencilImage, currentFillImage, currentStructureImage), timestamp: command.timestamp)
            currentPencilImage = pencilImage
            currentFillImage = fillImage
            currentStructureImage = structureImage
            redrawNewCell()
        }
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(redoDrawing(_:)), object: newCommand)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) { [weak self] in
            self?.refreshPreview()
        }
    }
    
    @objc func redoDrawing(_ command: DrawingCommand) {
        var newCommand: DrawingCommand?
        
        switch command.type {
        case .stroke(let previousStrokeImage):
            print("➡️ Redo stroke")
            newCommand = DrawingCommand(type: .stroke(currentStructureImage), timestamp: command.timestamp)
            currentStructureImage = previousStrokeImage
            self.redo()
            redraw()
        case .fill(let previousFillImage):
            print("➡️ Redo fill")
            newCommand = DrawingCommand(type: .fill(currentFillImage), timestamp: command.timestamp)
            currentFillImage = previousFillImage
            redraw()
        case .fillCell(let previousFillImage):
            print("➡️ Redo autofill cell")
            newCommand = DrawingCommand(type: .fillCell(currentFillImage), timestamp: command.timestamp)
            currentFillImage = previousFillImage
            redraw()
        case .cutAndPaste(let pencilImage, let fillImage, let structureImage):
            print("➡️ Redo cut & paste")
            newCommand = DrawingCommand(type: .cutAndPaste(currentPencilImage, currentFillImage, currentStructureImage), timestamp: command.timestamp)
            currentPencilImage = pencilImage
            currentFillImage = fillImage
            currentStructureImage = structureImage
            redrawNewCell()
        }
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(undoDrawing(_:)), object: newCommand)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) { [weak self] in
            self?.refreshPreview()
        }
    }
    
    @objc func resetUndo() {
        undoManager?.removeAllActions()
        sceneController?.updateUndoButtons()
    }
    
    
    // MARK: - Init
    
    @objc func configure() {
        isTouchEnabled = true
        setupNotifications()
        
        // Setup layers
        /// Clear base
        layer.backgroundColor = UIColor.clear.cgColor
        backgroundColor = UIColor.clear
        /// Clear previews
        compositedLayer.backgroundColor = UIColor.clear.cgColor
        lightboxLayer.backgroundColor = UIColor.clear.cgColor
        fillLayer.backgroundColor = UIColor.clear.cgColor
        fillLayer.magnificationFilter = .nearest
        layer.magnificationFilter = .nearest
        /// White background layer
        backgroundLayer.backgroundColor = UIColor.white.cgColor
        backgroundLayer.opacity = 1.0
        backgroundLayer.isOpaque = true
        /// Semi transparent lightbox
        lightboxLayer.opacity = 0.4
        
        self.superview?.layer.insertSublayer(backgroundLayer, below: self.layer)
        self.superview?.layer.insertSublayer(lightboxLayer, below: self.layer)
        self.superview?.layer.insertSublayer(fillLayer, below: self.layer)
        self.superview?.layer.insertSublayer(compositedLayer, below: self.layer)
#if DEBUG
        if isDebug {
            layer.addSublayer(debugLayer)
        }
#endif
        // Setup canvas
        zoom = 1
        
        if brush == nil {
            setupBrush()
        }
        
        let clearImage0 = FBImage(premultipliedImage: UIImage.clearImageOf(size: self.bounds.size))!
        let clearImage1 = FBImage(premultipliedImage: UIImage.clearImageOf(size: self.bounds.size))!
        
        // Pencil chartlet
        _ = try? makeTexture(with: clearImage0, id: kPencilChartletID)
        _ = try? makeTexture(with: clearImage1, id: kClearChartletID)
        
        if #available(iOS 12.1, *) {
            let pencilInteraction = UIPencilInteraction()
            pencilInteraction.delegate = self
            addInteraction(pencilInteraction)
        } else {
            // Fallback on earlier versions
        }
    }
        
    @objc func setupBrush() {
        var softness = 0.0
        let brushName = UserDefaults.standard.string(forKey: kCurrentBrushPrefKey) ?? "Ink"
        
        var texturePath: String?
        if isEraserTool {
            let hardness = UserDefaults.standard.integer(forKey: kCurrentEraserHardnessPrefKey)
            let number = min(max(0, hardness), 10) // Now it's softness.
            texturePath = Bundle.main.path(forResource: "Ink_\(number)", ofType: "png")
        } else if brushName == "Ink" {
            softness = UserDefaults.standard.double(forKey: kBrushSmoothingKey)
            texturePath = InkBrush.texturePathFor(hardness: softness)
        } else if brushName == "Pencil" {
            softness = UserDefaults.standard.double(forKey: kBrushSmoothingKey)
            texturePath = PencilBrush.texturePath(with: Int(softness))
        } else {
            texturePath = Bundle.main.path(forResource: brushName, ofType: "png")
        }
        
        guard let path = texturePath else {
            return
        }
        print("Changed brush texture to", texturePath ?? "nil")
        
        let brush: Brush
            
        if isEraserTool {
            let eraser: Eraser = try! registerBrush(from: URL(fileURLWithPath: path))
            brush = eraser
        } else {
            brush = try! registerBrush(from: URL(fileURLWithPath: path))
        }
        
        // Setup brush
        let minWidth = UserDefaults.standard.minPressureWidth(for: brushName)
        let maxWidth = UserDefaults.standard.maxPressureWidth(for: brushName)
        
        let eraserWidth = CGFloat(UserDefaults.standard.double(forKey: kCurrentEraserWidthPrefKey))
        
        let color = getCurrentColor()
        let alpha = getCurrentAlpha()
        brush.pointSizeMax = maxWidth
        brush.pointSizeMin = minWidth
        
        switch brushName {
        case "Ink":
            brush.rotation = .ahead
            brush.opacity = 1 - softness / 20
            brush.pointStep = 0.4
//            brush.rotation = .ahead
//            brush.opacity = 0.95
//            brush.pointStep = 1
        case "Pencil":
            brush.rotation = .random
            brush.opacity = 0.2
            brush.pointStep = maxWidth / 6
        case "Chalk":
            brush.rotation = .fixed(0)
            brush.opacity = 0.2
            brush.pointStep = 1
        default:
            break
        }
        
        brush.forceSensitive = 1.0
        brush.forceOnTap = 0.5
        brush.use()
        brush.color = color
        
        if isEraserTool {
            brush.pointSizeMax = eraserWidth
            brush.pointSizeMin = eraserWidth
        }
        
        brush.opacity = alpha
        
        self.brush = brush
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        backgroundLayer.frame = self.frame
        compositedLayer.frame = self.frame
        lightboxLayer.frame = self.frame
        fillLayer.frame = self.frame
#if DEBUG
        if isDebug {
            debugLayer.frame = frame
        }
#endif
        compositedLayer.sublayers?.forEach({ (sublayer) in
            sublayer.frame = compositedLayer.frame
        })
        
        CATransaction.commit()
        CATransaction.flush()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(prefsDidChangeNotification), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetUndo), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    private func updatePreferences() {
        let defaults = UserDefaults.standard
        /// FPS
        playbackFrameDuration = {
            let fps = UserDefaults.standard.float(forKey: kCurrentFramesPerSecondPrefKey)
            print("FPS: \(fps)")
            return TimeInterval(1.0 / fps)
        }()
        /// Fill
        let newFillTool = defaults.bool(forKey: kUsingFillToolPrefKey)
        if !self.prefUsingFillTool && newFillTool {
            /// Render structure
            composeStructureImage()
        }
        self.prefUsingFillTool = newFillTool
        /// Lightbox
        let isLightboxEnabled = defaults.bool(forKey: kLightboxEnabledPrefKey)
        if !isLightboxEnabled && currentLightboxImage != nil {
            currentLightboxImage = nil
            lightboxLayer.contents = nil
        }
        /// Configure brush
        self.setupBrush()
    }
    
    var isEraserTool: Bool {
        return UserDefaults.standard.bool(forKey: kUsingEraserToolPrefKey)
    }
    
    var isFillTool: Bool {
        return UserDefaults.standard.bool(forKey: kUsingFillToolPrefKey)
    }
    
    @objc func getCurrentColor() -> UIColor {
        return sceneController?.colorsController.selectedColor().uiColor() ?? UIColor.black
    }
    
    @objc func getCurrentAlpha() -> CGFloat {
        let defaults = UserDefaults.standard
        return CGFloat(defaults.float(forKey: kCurrentAlphaPrefKey))
    }

    @objc func prefsDidChangeNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updatePreferences()
        }
    }
    
    @objc public func redraw() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        CATransaction.setDisableActions(true)
        
        if let currentPlaybackImages = currentPlaybackImages {
            for (index, image) in currentPlaybackImages.enumerated() {
                compositedLayer.sublayers?[index].contents = image
            }
        } else {
            compositedLayer.sublayers?.forEach({ $0.contents = nil })
        }
        
        compositedLayer.contents = currentCompositedImage?.cgImage
        if (currentPlaybackImages != nil) || (currentCompositedImage != nil) {
            isTouchEnabled = false
            lightboxLayer.contents = nil
            fillLayer.contents = nil
            backgroundLayer.contents = nil
        } else {
            isTouchEnabled = true
            if UserDefaults.standard.bool(forKey: kLightboxEnabledPrefKey) {
                lightboxLayer.contents = currentLightboxImage?.cgImage
            } else {
                lightboxLayer.contents = nil
            }
            fillLayer.contents = currentFillImage?.cgImage
            backgroundLayer.contents = currentBackgroundImage?.cgImage
        }
        
#if DEBUG
        if isDebug {
            debugLayer.contents = currentStructureImage?.cgImage
        }
#endif
        
        CATransaction.commit()
        CATransaction.flush()
    }
    
    func redrawNewCell() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        
        resetData(redraw: false)
        renderChartlet(at: self.center, size: self.bounds.size, textureID: kPencilChartletID, rotation: 0)
        
        if (currentCompositedImage != nil) || (currentPlaybackImages != nil) {
            updatePencilChartletTexture(image: nil)
        } else {
            updatePencilChartletTexture(image: currentPencilImage)
        }
        
        compositedLayer.sublayers?.forEach({ $0.contents = nil })
        compositedLayer.contents = currentCompositedImage?.cgImage
        if (currentPlaybackImages != nil) || (currentCompositedImage != nil) {
            isTouchEnabled = false
            lightboxLayer.contents = nil
            fillLayer.contents = nil
            backgroundLayer.contents = nil
        } else {
            isTouchEnabled = true
            if UserDefaults.standard.bool(forKey: kLightboxEnabledPrefKey) {
                lightboxLayer.contents = currentLightboxImage?.cgImage
            } else {
                lightboxLayer.contents = nil
            }
            fillLayer.contents = currentFillImage?.cgImage
            backgroundLayer.contents = currentBackgroundImage?.cgImage
        }
        super.redraw()
        
#if DEBUG
        if isDebug {
            debugLayer.contents = currentStructureImage?.cgImage
        }
#endif
        
        CATransaction.commit()
        CATransaction.flush()
    }
    
    func updatePencilChartletTexture(image: FBImage?) {
        if let image = image {
            _ = try? replaceTexture(withNew: image, by: kPencilChartletID)
        } else {
            if let pencilChartlet = data.elements.first(where: { $0 is Chartlet }) as? Chartlet {
                pencilChartlet.textureID = kClearChartletID
            }
        }
        super.redraw()
    }
    
    // MARK: - Fill
    
    func fill(at point: CGPoint, isEraser: Bool? = nil, inLoop: Bool = false) {
        
        var previousFill: FBImage?
        
        if !inLoop {
            previousFill = currentFillImage?.copyImage()
            if currentFillImage == nil {
                currentFillImage = FBImage(size: self.bounds.size, fillColor: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
            }
        }
        
        let line_img = currentStructureImage
                
        var fill_color = getCurrentColor().withAlphaComponent(getCurrentAlpha()).cgColor
        let isEraser = isEraser ?? isEraserTool
        if isEraser {
            fill_color = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        }
        
        if let line_img = line_img {
            let line_img_color = line_img.cgImage.pixelColorAt(x: Int(point.x), y: Int(point.y))
            // Check if trying to fill under line
            guard (line_img_color.components?.map({ (component) -> CGFloat in
                if component.isNaN {
                    return 0.0
                } else {
                    return component
                }
            }).reduce(0, +) ?? 0.0) < 1.0 else {
                return
            }
        }
        
        var current_color: CGColor? = nil
        
        guard self.bounds.contains(point) else {
            return
        }
        
        current_color = currentFillImage?.cgImage.pixelColorAt(x: Int(point.x), y: Int(point.y))
                
        if !(current_color?.isLike(fill_color) ?? false) {
            if let line_img = line_img {
                let threshold = SettingsBundleHelper.threshold
                currentFillImage?.fill(at: point, structure: line_img, color: fill_color, threshold: threshold, colorToErase: isEraser ? current_color : nil)
            } else {
                currentFillImage = FBImage.init(size: self.bounds.size, fillColor: UIColor(cgColor: fill_color))
            }
            if !inLoop { self.fillFinished(previousImage: previousFill) }
        }
    }
    
    // MARK: - Playback
    
    @objc var playbackSpeed: Double = 1.0
    
    private let MAX_SPEED = 8.0
    private let MIN_SPEED = 0.125
    
    @objc func speedUp() -> Bool {
        defer {
            self.playback?.nextCommand = .rateUpdate
        }
        if playbackSpeed < (MAX_SPEED + 0.01) / 2 {
            playbackSpeed *= 2
            return true
        } else {
            playbackSpeed = MAX_SPEED
            return false
        }
    }
    
    @objc func speedDown() -> Bool {
        defer {
            self.playback?.nextCommand = .rateUpdate
        }
        if playbackSpeed > (MIN_SPEED - 0.01) * 2 {
            playbackSpeed *= 0.5
            return true
        } else {
            playbackSpeed = MIN_SPEED
            return false
        }
    }
    
    private var playbackFrameDuration: TimeInterval!
    
    func prepareForPlaybackWith(levelsCount: Int) {
        let delta = (2 * levelsCount - (compositedLayer.sublayers?.count ?? 0))
        if delta > 0 {
            for _ in 0..<delta {
                let levelLayer = CALayer()
                levelLayer.frame = compositedLayer.bounds
                compositedLayer.addSublayer(levelLayer)
            }
        }
        if delta < 0 {
            for _ in 0..<delta {
                compositedLayer.sublayers?.first?.removeFromSuperlayer()
            }
        }
    }

    class Playback {
        let storage: FBXsheetStorage
        let soundData: Data?
        
        let numberOfRows: Int
        let numberOfColumns: Int
        let hiddenColumns: [Int]
//        var lastImages: [CGImage?]
        
        var playbackStartTimestamp: CFAbsoluteTime
        var playbackInterval: TimeInterval
        
        var playbackTimer: DispatchSourceTimer?
        var soundPlayer: AVAudioPlayer? = nil
        
        // Commands
        
        enum Command {
            enum StopMode {
                case start
                case end
            }
            enum PauseMode {
                case silent
                case update
            }
            
            case stop(StopMode)
            case pause(PauseMode)
            case rateUpdate
        }
        
        var nextCommand: Command?
        
        // State
        
        enum State {
            case playing
            case paused(Int)
        }
        
        var state: State = .playing
        
        // Init
        
        init(storage: FBXsheetStorage, database: FBSceneDatabase, soundData: Data?, playbackInterval: TimeInterval, playbackTimer: DispatchSourceTimer, fromIndex: Int) {
            self.storage = storage
            self.soundData = soundData
            
            self.numberOfRows = storage.numberOfRows
            self.numberOfColumns = storage.numberOfColumns
            var hiddenColumns = [Int]()
            for col in 0..<numberOfColumns {
                if database.isLevelHidden(at: col) {
                    hiddenColumns.append(col)
                }
            }
            self.hiddenColumns = hiddenColumns
                
//            self.lastImages = Array.init(repeating: nil, count: self.numberOfColumns * 2)
//            for i in 0..<self.numberOfColumns {
//                let paintIdx = 2 * i
//                let pencilIdx = (2 * i) + 1
//
//                let cel = storage.previousCellAt(row: fromIndex + 2, column: i + 1)
//
//                self.lastImages[paintIdx] = cel?.paintImage?.cgImage
//                self.lastImages[pencilIdx] = cel?.pencilImage?.cgImage
//            }
            
            self.playbackStartTimestamp = CFAbsoluteTimeGetCurrent() - (Double(fromIndex) * playbackInterval)
            self.playbackInterval = playbackInterval
            
            self.playbackTimer = playbackTimer
            
            if let soundData = soundData {
                do {
                    self.soundPlayer = try AVAudioPlayer(data: soundData)
                    self.soundPlayer?.enableRate = true
                    self.soundPlayer?.volume = 1.0
                    self.soundPlayer?.prepareToPlay()
                } catch {
                    print("🔥", error.localizedDescription)
                }
            }
        }
        
        deinit {
            playbackTimer = nil
            soundPlayer?.pause()
            soundPlayer = nil
        }
    }
    
    private var playback: Playback?
    
    @objc func playSequence(fromDocumentStorage storage: FBXsheetStorage, soundData: NSData?) {
        var fromIndex = 0
        if let playback = playback, case Playback.State.paused(let index) = playback.state {
            fromIndex = index
        }
        playSequence(fromDocumentStorage: storage, soundData: soundData, fromIndex: fromIndex)
    }
    
    let playbackRenderingQueue = DispatchQueue(label: "playbackRenderingQueue", qos: .userInteractive)
    
    @objc func playSequence(fromDocumentStorage storage: FBXsheetStorage, soundData: NSData?, fromIndex: Int) {
        // Prepare cell layers
        self.prepareForPlaybackWith(levelsCount: storage.numberOfColumns)
        
        playbackRenderingQueue.async {
            let playbackInterval = self.playbackFrameDuration / self.playbackSpeed

            // Timer
            let playbackTimer = DispatchSource.makeTimerSource(queue: self.playbackRenderingQueue)
            playbackTimer.setEventHandler(handler: self.updateFrame)
            playbackTimer.schedule(deadline: .now(), repeating: .milliseconds(Int(playbackInterval * 1000.0)), leeway: .milliseconds(50))
            playbackTimer.resume()
            
            
            // Playback
            self.playback = Playback(storage: storage, database: self.sceneController!.document.database, soundData: soundData as Data?, playbackInterval: playbackInterval, playbackTimer: playbackTimer, fromIndex: fromIndex)
            self.playback?.soundPlayer?.play()
            self.playback?.soundPlayer?.rate = Float(self.playbackSpeed)
            
            
            // Sound
            let playbackSpeed = self.playbackSpeed
            let soundOffsetSeconds = Double(self.sceneController?.document.soundOffset() ?? 0.0) * playbackInterval
            let playbackStartIndexOffsetSeconds = Double(fromIndex) * playbackInterval
            let playbackOffset = soundOffsetSeconds - playbackStartIndexOffsetSeconds
            
            if playbackOffset < 0.0 {
                self.playback?.soundPlayer?.currentTime = abs(playbackOffset)
            } else {
                self.playback?.soundPlayer?.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(playbackOffset * 1000))) {
                    self.playback?.soundPlayer?.play()
                    self.playback?.soundPlayer?.rate = Float(playbackSpeed)
                }
            }
        }
    }
    
    func updateFrame() {
        guard let playback = self.playback else { return }
            
        let nowTimestamp = CFAbsoluteTimeGetCurrent()
        let secondsFromStart = nowTimestamp - playback.playbackStartTimestamp
            
        let framesFromStart = (secondsFromStart / playback.playbackInterval)
        let index = Int(framesFromStart.rounded(.toNearestOrAwayFromZero))
        
        // Slider position
        let position = CGFloat(index) / CGFloat(playback.storage.numberOfRows - 1)
            
        autoreleasepool {
            // Handle command
            if let command = playback.nextCommand {
                playback.nextCommand = nil
                switch command {
                case .pause(let pauseMode):
                    self.playback?.playbackTimer = nil
                    self.playback?.state = .paused(index)
                    self.playback?.soundPlayer?.pause()
                    self.playback?.soundPlayer = nil
                    
                    DispatchQueue.main.async {
                        var previousIndex = min(index-1, playback.numberOfRows-1)
                        if previousIndex < 0 {
                            previousIndex = playback.numberOfRows-1
                        }
                        
                        switch pauseMode {
                        case .silent:
                            break
                        case .update:
                            self.drawingDelegate?.didPauseOn(row: previousIndex)
                            self.sceneController?.didMove(toRelativePosition: min(position, 1.0))
                        }
                    }
                    
                    return
                case .stop(let stopMode):
                    DispatchQueue.main.async {
                        self.playback = nil
                            
                        switch stopMode {
                        case .start:
                            self.drawingDelegate?.didPauseOn(row: 0)
                            self.sceneController?.didMove(toRelativePosition: 0.0)
                        case .end:
                            self.drawingDelegate?.didPauseOn(row: playback.numberOfRows - 1)
                            self.sceneController?.didMove(toRelativePosition: 1.0)
                        }
                    }
                    return
                case .rateUpdate:
                    DispatchQueue.main.async {
                        self.playSequence(fromDocumentStorage: playback.storage, soundData: playback.soundData as NSData?, fromIndex: index + 1)
                    }
                }
                return
            }
                
            DispatchQueue.main.async {
                self.sceneController?.didMove(toRelativePosition: min(position, 1.0))
            }
            
            // Play
            print("Showing", framesFromStart, index, "/", playback.numberOfRows)
            if index < playback.numberOfRows {
//                var images = Array<CGImage?>.init(repeating: nil, count: playback.numberOfColumns * 2)
//
                let row = index + 1
//                for col in 1...playback.numberOfColumns {
//                    guard !playback.hiddenColumns.contains(col - 1) else {
//                        continue
//                    }
//
//                    var currentCell: FBCell?
//                    if let cell = playback.storage.cellAt(row: row, column: col), !cell.isEmpty() {
//                        currentCell = cell
//                    }
//
//                    let paintIdx = 2 * (col - 1)
//                    if let paintImage = currentCell?.paintImage?.cgImage {
//                        playback.lastImages[paintIdx] = paintImage
//                        images[paintIdx] = paintImage
//                    } else {
//                        if let backgroundImage = currentCell?.backgroundImage?.cgImage {
//                            playback.lastImages[paintIdx] = backgroundImage
//                            images[paintIdx] = backgroundImage
//                        } else {
//                            images[paintIdx] = playback.lastImages[paintIdx]
//                        }
//                    }
//
//                    let pencilIdx = 2 * (col - 1) + 1
//                    if let pencilImage = currentCell?.pencilImage?.cgImage {
//                        playback.lastImages[pencilIdx] = pencilImage
//                        images[pencilIdx] = pencilImage
//                    } else {
//                        images[pencilIdx] = playback.lastImages[pencilIdx]
//                    }
//                }
//
//                DispatchQueue.main.async {
//                    self.showCompositedFrameImages(images)
//                }
                
                var compositeImage: UIImage?
                if let image = playback.storage.compositeAt(row:row) {
                    compositeImage = image
                }
                
                DispatchQueue.main.async {
                    self.showCompositedFrameImage(compositeImage)
                }
                
            } else {
                if UserDefaults.standard.bool(forKey: kLoopEnabledPrefKey) {
                    DispatchQueue.main.async {
                        self.playSequence(fromDocumentStorage: playback.storage, soundData: playback.soundData as NSData?, fromIndex: 0)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.playback = nil
                        self.drawingDelegate?.didPauseOn(row: playback.numberOfRows - 1)
                    }
                }
            }
        }
    }
    
    @objc func stopSequenceAtStart() {
        self.playback?.nextCommand = .stop(.start)
    }
    
    @objc func stopSequenceAtEnd() {
        self.playback?.nextCommand = .stop(.end)
    }
    
    @objc func pauseSequenceWithFrameUpdate(_ withFrameUpdate: Bool) {
        self.playback?.nextCommand = .pause(withFrameUpdate ? .update : .silent)
    }
    
    func showCompositedFrameImages(_ images: [CGImage?]) {
        resetData(redraw: true)
        
        currentPlaybackImages = images
        currentCompositedImage = nil
        
        redraw()
    }

    @objc func showCompositedFrameImage(_ image: UIImage?) {
        resetData(redraw: true)
        
        currentPlaybackImages = nil
        currentCompositedImage = image

        redraw()
    }

    @objc func clearCurrentCellLeavingLightbox(_ image: UIImage?) {
        resetData(redraw: true)
        
        currentLightboxImage = image
        currentPencilImage = nil
        currentFillImage = nil
        currentStructureImage = nil
        
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        redraw()
    }

    @objc func updateLightboxWithImage(_ image: UIImage?) {
        currentLightboxImage = image
        
        redraw()
    }
    
    
    // MARK: - Snaphots
    
    func pencilImage() -> FBImage? {
        return snapshot()
    }
    
    
    struct StructureLayer {
        let strips: [LineStrip]
        let isEraser: Bool
    }
    
    func structureImage() -> FBImage? {
        return snapshot()
        let allLines = self.data.elements.filter({ $0 is LineStrip }) as! [LineStrip]
        
        guard !allLines.isEmpty else {
            return currentStructureImage ?? FBImage(premultipliedImage: UIImage.clearImageOf(size: self.bounds.size))
        }
        
        var layers = [StructureLayer]()
        
        var strips = [LineStrip]()
        var eraser: Bool = allLines.first!.isEraser
        
        for line in allLines {
            let newEraser = line.isEraser
            if newEraser == eraser {
                strips.append(line)
            } else {
                layers.append(StructureLayer(strips: strips, isEraser: eraser))
                strips = [line]
                eraser = newEraser
            }
        }
        if !strips.isEmpty {
            layers.append(StructureLayer(strips: strips, isEraser: eraser))
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        currentStructureImage?.previewUiImage.draw(at: .zero)
        for layer in layers {
            if layer.isEraser {
                let eraser = renderStructure(lineStrips: layer.strips, widthMultiplier: 1.0)
                eraser?.draw(at: .zero, blendMode: .destinationOut, alpha: 1.0)
            } else {
                let structure = renderStructure(lineStrips: layer.strips, widthMultiplier: 1.0)
                structure?.draw(at: .zero)
            }
        }
        
        let composedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        context?.restoreGState()
        UIGraphicsEndImageContext()
        
        return FBImage(premultipliedImage: composedImage)
    }
    
    func renderStructure(lineStrips: [LineStrip], widthMultiplier: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setAllowsAntialiasing(false)
        ctx?.saveGState()
        
        ctx?.setStrokeColor(UIColor.black.cgColor)
        
        for strip in lineStrips {
            var lines = strip.lines
            
            if lines.count > 2 {
                if let line = lines.first {
                    var startOffset: CGFloat = line.pointSize / 2.0
                    while (startOffset > 0.0) && !lines.isEmpty {
                        let line = lines.removeFirst()
                        startOffset -= line.length
                    }
                }
                if let line = lines.first {
                    var endOffset: CGFloat = line.pointSize / 2.0
                    while (endOffset > 0.0) && !lines.isEmpty {
                        let line = lines.removeLast()
                        endOffset -= line.length
                    }
                }
            }
            
            for line in lines {
                let width = line.pointSize * line.hardness * widthMultiplier
                ctx?.setLineWidth(width)
                ctx?.setLineCap(.round)
                ctx?.strokeLineSegments(between: [line.begin, line.end])
            }
        }
        
        let structureImage = UIGraphicsGetImageFromCurrentImageContext()
        ctx?.restoreGState()
        UIGraphicsEndImageContext()
        return structureImage
    }
    
    func composeStructureImage() {
        currentStructureImage = structureImage()
    }
    
    
    // MARK: - Saving
    
    let previewRenderingQueue = DispatchQueue(label: "previewRenderingQueue", qos: .userInteractive)
    func refreshPreview() {
        let currentFillImage = self.currentFillImage
        let currentPencilImage = self.currentPencilImage
        let currentDrawings = self.snapshot()
        
        guard (currentFillImage != nil) || (currentPencilImage != nil) || !self.data.elements.filter({ !($0 is Chartlet) }).isEmpty else {
            self.drawingDelegate?.refreshCellPreview(image: nil)
            return
        }
        
        let bounds = self.bounds
        
        previewRenderingQueue.async { [weak self] in
            UIGraphicsBeginImageContext(bounds.size)
            currentFillImage?.previewUiImage.draw(in: bounds)
            currentPencilImage?.previewUiImage.draw(in: bounds)
            currentDrawings?.previewUiImage.draw(in: bounds)
            let inacurateSnapshot = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                self?.drawingDelegate?.refreshCellPreview(image: FBImage(premultipliedImage: inacurateSnapshot))
            }
        }
    }
    
    func refreshPreviewPrecise() {
        let currentFillImage = self.currentFillImage
        let currentPencilImage = self.currentPencilImage
        let currentBackgroundImage = self.currentBackgroundImage
        let currentDrawings = self.snapshot()
        
        guard (currentFillImage != nil) || (currentPencilImage != nil) || (currentBackgroundImage != nil) || !self.data.elements.filter({ !($0 is Chartlet) }).isEmpty else {
            self.drawingDelegate?.refreshCellPreview(image: nil)
            return
        }
        
        let bounds = self.bounds
        
        UIGraphicsBeginImageContext(bounds.size)
        currentBackgroundImage?.previewUiImage.draw(in: bounds)
        currentFillImage?.previewUiImage.draw(in: bounds)
        currentPencilImage?.previewUiImage.draw(in: bounds)
        currentDrawings?.previewUiImage.draw(in: bounds)
        let acurateSnapshot = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let previewImage = FBImage(premultipliedImage: acurateSnapshot)
        
        self.drawingDelegate?.refreshCellPreview(image: previewImage)
    }
    
    @objc func saveChangesSilently() {
        guard (currentCompositedImage == nil) && (currentPlaybackImages == nil) else {
            return
        }
        
        guard !self.data.elements.filter({ !($0 is Chartlet) }).isEmpty || currentPencilImage != nil || currentStructureImage != nil else {
            return
        }
        
        let pencil = pencilImage()
        let structure = structureImage()
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 1)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        context?.interpolationQuality = .high
        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)
        context?.clear(self.bounds)
                
//        pencil?.draw(in: self.bounds)
//        let composedPencil = UIGraphicsGetImageFromCurrentImageContext()

//        context?.restoreGState()
//        context?.clear(self.bounds)
        
        currentStructureImage?.previewUiImage.draw(in: bounds)
        structure?.previewUiImage.draw(in: bounds)
        let composedStructure = UIGraphicsGetImageFromCurrentImageContext()!
        
        context?.restoreGState()
        UIGraphicsEndImageContext()
        
        drawingDelegate?.update(pencilImage: pencil, structureImage: FBImage(premultipliedImage: composedStructure), fillImage: currentFillImage)
    }
    
    @objc func saveChanges() {
        saveChangesSilently()
        resetUndo()
    }
    
    @objc func hasChanges() -> Bool {
        return lastCommand != nil
    }
    
    
    // MARK: - Loading
    
    @objc func loadNewCelWithImages(_ info: [String: Any]) {
        let pencil_img = info[kUpdateCurrentCellPencilKey] as? FBImage
        let paint_img = info[kUpdateCurrentCellPaintKey] as? FBImage
        let structure_img = info[kUpdateCurrentCellStructureKey] as? FBImage
        let background_img = info[kUpdateCurrentCellBackgroundKey] as? FBImage
        let lightbox_img = info[kUpdateCurrentLightboxImageKey] as? UIImage
        
        currentLightboxImage = lightbox_img
        currentPencilImage = pencil_img
        currentFillImage = paint_img
        currentStructureImage = structure_img
        currentBackgroundImage = background_img
        
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        redrawNewCell()
        refreshPreviewPrecise()
    }
    
    @objc func updateCelWithImages(_ info: [String: Any]) {
        if let pencil_img = info[kUpdateCurrentCellPencilKey] as? FBImage {
            currentPencilImage = pencil_img
        }
        if let paint_img = info[kUpdateCurrentCellPaintKey] as? FBImage {
            currentFillImage = paint_img
        }
        if let structure_img = info[kUpdateCurrentCellStructureKey] as? FBImage {
            currentStructureImage = structure_img
        }
        if let lightbox_img = info[kUpdateCurrentLightboxImageKey] as? UIImage {
            currentLightboxImage = lightbox_img
        }
        
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        redrawNewCell()
        refreshPreviewPrecise()
    }
    
    @objc func getCurrentImages() -> [String: FBImage] {
        var images = [String: FBImage]()
        if let pencil = currentPencilImage {
            images[kUpdateCurrentCellPencilKey] = pencil
        }
        if let fill = currentFillImage {
            images[kUpdateCurrentCellPaintKey] = fill
        }
        if let structure = currentStructureImage {
            images[kUpdateCurrentCellStructureKey] = structure
        }
        return images
    }
        
    
    // MARK: - Touches processing
    
    var strokeStartTimestamp: TimeInterval = 0
    var strokeStartLocation: CGPoint?
    var startingPoint = CGPoint(x: 0, y: 0)
    private var timer: Timer?
    
    private var time: Int = 0
    private var locations = [CGPoint]()
    private var beginTouchLocation: CGPoint?
    
    private var lastMarkFrame: CGRect = .zero
    
    private var startPixelColorAtFillImage: CGColor? = nil
    private var startPixelColorAtPencilImage: CGColor? = nil
    
    private var isTouchedNow = false
    private var isTouchMoved = false
    private var canFillBeginLocation = true
    private var permissionGranded = false
    
    private let defaultColor = UIColor.clear.cgColor
    
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("touchesBegan")
        let previousSelection: String = UserDefaults.standard.string(forKey: kCurrentShapePrefKey) ?? ""
        if !prefUsingFillTool {
            
            if let touch = touches.first {
                let position = touch.location(in: self)
                
                if previousSelection == "Multilines" && !isEraserTool && !isFillTool {
                    if UserDefaults.standard.bool(forKey: kMultilineVanishingPoint) != true{
                        startingPoint = position
                        UserDefaults.standard.set(true, forKey: kMultilineVanishingPoint)
                    }else{
//                        let directionX = position.x - startingPoint.x
//                        let directionY = position.y - startingPoint.y
//                        let slope = directionY / directionX
//
//                        var maxX: Double
//                        var maxY: Double
//
//                        if directionX >= 0 {
//                            // Right side of the frame.
//                            maxX = self.layer.frame.width
//                            maxY = startingPoint.y + (self.layer.frame.width - startingPoint.x) * slope
//
//                            if maxY > self.layer.frame.height {
//                                maxY = self.layer.frame.height
//                                maxX = startingPoint.x + (self.layer.frame.height - startingPoint.y) / slope
//                            }
//                        } else {
//                            // Left side of the frame.
//                            maxX = 0
//                            maxY = startingPoint.y - startingPoint.x * slope
//
//                            if maxY < 0 {
//                                maxY = 0
//                                maxX = startingPoint.x - startingPoint.y / slope
//                            }
//                        }
//
                        drawLine(onLayer: self.layer, fromPoint: startingPoint, toPoint: position)
                    }
                }else{
                    drawLine(onLayer: self.layer, fromPoint: startPoint, toPoint: endPointPoint)
                    isStarted = true
                }
                startPoint = position
                endPointPoint = position
            }
        }
        self.isTouchedNow = true
        self.isTouchMoved = false
        self.canFillBeginLocation = true
        self.permissionGranded = FeatureManager.shared.checkSubscribtion(.lite)
        
        guard isTouchEnabled, let touch = touches.first else { return }
                
        let location = touch.location(in: self)
        
        self.beginTouchLocation = location
        
        self.startPixelColorAtFillImage = currentFillImage?.cgImage.pixelColorAt(location)
        self.startPixelColorAtPencilImage = currentPencilImage?.cgImage.pixelColorAt(location)

        strokeStartTimestamp = ProcessInfo().systemUptime
        strokeStartLocation = location
        
        
        if prefUsingFillTool {
            
            switch fillMode {
            case .normal:
                
//                time = 0
//                timer?.invalidate()
                timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    
                    if self.time > 15 && self.isTouchMoved == false {
                        self.drawingDelegate?.fillLevelCells(onlyCurrentCell: true)
                        self.timer?.invalidate()
                        self.timer = nil
                        return
                    }
                    self.time += 1
                }
                RunLoop.main.add(timer!, forMode: .common)
                
            default: break
                
            }
        }
        
        // If Pencil is selected & shape drawing is enabled.. Don't call
        if previousSelection != "" && previousSelection != "Multilines" && !isEraserTool && !isFillTool {
            return
        }

        super.touchesBegan(touches, with: event)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("touchesMoved")

        if !prefUsingFillTool {
            if let touch = touches.first {
                let position = touch.location(in: self)
                endPointPoint = position
                drawLine(onLayer: self.layer, fromPoint: startPoint, toPoint: endPointPoint)
            }
        }
        
        guard isTouchEnabled else { return }
        guard prefUsingFillTool else { super.touchesMoved(touches, with: event); return }
        
        //        if !prefUsingFillTool { super.touchesMoved(touches, with: event) } else {
        
//        guard let touch = touches.first, let beginTouchLocation = touches.first?.location(in: self) else { return }
        guard let touch = touches.first, let beginTouchLocation else { return }
        
        let currentlocation = touch.location(in: self)
        let prevLocation = touch.previousLocation(in: self)
        
        self.isTouchMoved = beginTouchLocation.distance(to: currentlocation) > 15
        
        guard isTouchMoved else { return }
        
        guard permissionGranded else {
            UIAlertController.showBlockedAlertController(for: sceneController ?? UIViewController(), feature: "Drag and fill", level: "Lite")
            return
        }
        
        if canFillBeginLocation {
            fill(at: beginTouchLocation)
            canFillBeginLocation = false
        }
        
        let prevPixColorAtStructImage = currentStructureImage?.cgImage.pixelColorAt(prevLocation) ?? defaultColor
        let currentPixColorAtStructImage = currentStructureImage?.cgImage.pixelColorAt(currentlocation) ?? defaultColor
        
        if
            currentPixColorAtStructImage != prevPixColorAtStructImage
                && prevPixColorAtStructImage != startPixelColorAtFillImage
                && currentPixColorAtStructImage.isLike(defaultColor)
                
        {
            self.fill(at: currentlocation)
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("touchesEnded")
        if !prefUsingFillTool {
            isStarted = false
        }
    
        time = 0
        timer?.invalidate()
        
        self.isTouchedNow = false
        self.permissionGranded = false
        self.lastMarkFrame = .zero
        
        self.startPixelColorAtFillImage = nil
        self.startPixelColorAtPencilImage = nil

        guard isTouchEnabled else { return }
        
        if prefUsingFillTool {
            
            guard let touch = touches.first else { return }
            
            let location = touch.location(in: self)
            switch fillMode {
            case .normal:
                
                if time < 8 && self.isTouchMoved == false {
                    fill(at: location)
                    timer?.invalidate()
                    timer = nil
                }

            case .autoAdvance:
                fill(at: location)
                saveChanges()
                drawingDelegate?.selectNextRowWithContent()
                
            case .autoFillLevel:
                break
                                
            default: break
                
            }
        } else {
            super.touchesEnded(touches, with: event)
            renderCompletion = {
                DispatchQueue.main.async { [weak self] in
                    self?.strokeFinished()
                }
            }
        }
        
        self.beginTouchLocation = nil
        
    }
            
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("touchesCancelled")
        if !prefUsingFillTool {
            isStarted = false
        }
        
        time = 0
        timer?.invalidate()

        self.isTouchedNow = false
        self.permissionGranded = false

        self.beginTouchLocation = nil

        guard isTouchEnabled else { return }
        
        if prefUsingFillTool {
            if let lastCommand = lastCommand {
                if strokeStartTimestamp < lastCommand.timestamp {
                    undoManager?.undo()
                }
            }
        } else {
            super.touchesEnded(touches, with: event)
            strokeFinished()
            undoManager?.undo()
        }
    }
    
    // MARK: - Handling stroke
    
    func strokeFinished() {
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        let previousStructureImage = currentStructureImage
        
        if isEraserTool {
            // Substruct stroke from structure image
            composeStructureImage()
        }
        
        redraw()
        refreshPreview()
        
        let strokeCommand = DrawingCommand(type: .stroke(previousStructureImage))
        lastCommand = strokeCommand
        undoManager?.registerUndo(withTarget: self, selector: #selector(undoDrawing), object: strokeCommand)
        sceneController?.updateUndoButtons()
    }
    
    func fillFinished(previousImage: FBImage?) {
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        redraw()
        refreshPreviewPrecise()
        
        let fillCommand = DrawingCommand(type: .fill(previousImage))
        lastCommand = fillCommand
        
        undoManager?.registerUndo(withTarget: self, selector: #selector(undoDrawing), object: lastCommand)
        sceneController?.updateUndoButtons()
    }
    
   @objc func autofillCellFinished(previousImage: FBImage?) {
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        redraw()
        refreshPreviewPrecise()
        
        let fillCellCommand = DrawingCommand(type: .fillCell(previousImage))
        lastCommand = fillCellCommand
       
       DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
           guard let self = self else { return }
           self.undoManager?.registerUndo(withTarget: self, selector: #selector(self.undoDrawing), object: fillCellCommand)
           self.sceneController?.updateUndoButtons()
          
          SettingsBundleHelper.editModeDevice = false

       }
    }
    
    @objc func saveCurrentStateBeforeCutAndPaste() {
        currentCompositedImage = nil
        currentPlaybackImages = nil
        
        redraw()
        refreshPreviewPrecise()
                
        let cutAndPasteCommand = DrawingCommand(type: .cutAndPaste(currentPencilImage, currentFillImage, currentStructureImage))
        lastCommand = cutAndPasteCommand
        undoManager?.registerUndo(withTarget: self, selector: #selector(undoDrawing), object: cutAndPasteCommand)
        sceneController?.updateUndoButtons()
    }
    
    // MARK: - Deinit
  
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }
}

@available(iOS 12.1, *)
extension FBDrawingView: UIPencilInteractionDelegate {
    
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        
        sceneController?.toggleEraserTool()

    }
}
