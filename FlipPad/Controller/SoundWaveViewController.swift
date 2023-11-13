//
//  SoundWaveViewController.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 3/24/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

fileprivate let HEADER_HEIGHT: CGFloat = 30.0 // header height

fileprivate let FRAME_HEIGHT: CGFloat = 60.0 // pt

fileprivate let WAVE_STEP: CGFloat = 1.0 // pt

fileprivate let WAVES_PER_FRAME: Int = Int(FRAME_HEIGHT / WAVE_STEP) // n

fileprivate let WAVE_PADDING: CGFloat = 4.0

fileprivate func POINTS_PER_SECOND(FPS: Int) -> CGFloat {
    return FRAME_HEIGHT * CGFloat(FPS)
}

class SoundWaveView: UIView {
    
    var values = [Float]() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var height: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var scrollOffset: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var audioOffset: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var isLocked: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var headerTitle: String = "Sound"
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
                
        let context = UIGraphicsGetCurrentContext()
        
        UIColor.black.setStroke()
        
        let initialOffset = -scrollOffset + audioOffset + HEADER_HEIGHT
        let interlineOffset = WAVE_STEP
        
        var previousPoint = CGPoint(x: 0.5 * bounds.width, y: initialOffset)
        
        var lastValues: [CGFloat] = []
        var movingAverage: CGFloat {
            return lastValues.reduce(0.0, +) / CGFloat(lastValues.count)
        }
        
        for (index, location) in values.map({ CGFloat($0) }).enumerated() {
            let yOffset = initialOffset + (interlineOffset * CGFloat(index))
            if yOffset < 0.0 {
                continue
            }
            if bounds.height < yOffset {
                break
            }
                        
            lastValues.append(location)
            if lastValues.count > 16 {
                lastValues.removeFirst()
            }
            
            let originalLocation = (location * bounds.width)
            
            let average = movingAverage
            let extraOffset = bounds.width * (0.5 - average)
            
            let adjustedLocation = min(max(0.0, extraOffset + originalLocation), bounds.width)
            let paddedLocation = WAVE_PADDING + adjustedLocation * ((bounds.width - (2 * WAVE_PADDING)) / bounds.width)
            
            let nextPoint = CGPoint(x: paddedLocation, y: yOffset)
            
            context?.strokeLineSegments(between: [previousPoint, nextPoint])
            
            previousPoint = nextPoint
        }
        
        // Top background
        if scrollOffset < 0.0 {
            UIColor.lightGray.setFill()
            context?.fill(CGRect(origin: .zero, size: CGSize(width: bounds.width, height: -scrollOffset)))
        }
        
        // Header fill
        let headerRect = CGRect(origin: CGPoint(x: 0.0, y: -min(0.0, scrollOffset) - 0.5),
                                size: CGSize(width: bounds.width, height: HEADER_HEIGHT))
        UIColor.white.setFill()
        context?.fill(headerRect)
        
        // Left border
        UIColor(red: 0.66, green: 0.66, blue: 0.66, alpha: 1.0).setStroke()
        context?.setLineWidth(2.0)
        context?.strokeLineSegments(between: [CGPoint(x: 0.0, y: -scrollOffset), CGPoint(x: 0.0, y: bounds.maxY)])
        
        // Header top & bottom borders
        context?.setLineWidth(1.0)
        context?.strokeLineSegments(between: [CGPoint(x: 0.0, y: headerRect.minY),
                                              CGPoint(x: headerRect.width, y: headerRect.minY)])
        context?.strokeLineSegments(between: [CGPoint(x: 0.0, y: headerRect.maxY),
                                              CGPoint(x: headerRect.width, y: headerRect.maxY)])
        // Header title
        let attrString = NSAttributedString(string: headerTitle, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11.0, weight: .light),
            NSAttributedString.Key.foregroundColor: UIColor.black
        ])
        let size = attrString.size()
        attrString.draw(at: headerRect.origin.offsetedBy(x: (headerRect.width - size.width) / 2.0,
                                                         y: (headerRect.height - size.height) / 2.0))
        
        if isLocked {
            UIColor.red.withAlphaComponent(0.1).setFill()
            context?.fill(bounds.offsetBy(dx: 0.0, dy: headerRect.maxY))
        }
    }
    
}

@objc protocol SoundWaveViewControllerDelegate: class {
    
    func didChangeOffset(to newOffset: CGFloat)
    
    func didLongPressSoundHeader(view: UIView, rect: CGRect)
    
}

class SoundWaveViewController: UIViewController {
    
    @objc weak var delegate: SoundWaveViewControllerDelegate?
    
    // Offsets
    
    private var scrollOffset: CGFloat = 0.0 // Offset of tableview in points
    private var audioOffset: CGFloat = 0.0 // Offset of audio track in frames
    
    //
    
    @objc var titleRect: CGRect {
        return CGRect(origin: CGPoint(x: 0.0, y: -min(0.0, scrollOffset) - 0.5),
                      size: CGSize(width: view.bounds.width, height: HEADER_HEIGHT))
    }
    
    @objc var isLocked: Bool = false {
        didSet {
            (view as! SoundWaveView).isLocked = isLocked
        }
    }
    
    @objc var headerTitle: String {
        get {
            (view as! SoundWaveView).headerTitle
        }
        set {
            (view as! SoundWaveView).headerTitle = newValue
            view.setNeedsDisplay()
        }
    }
    
    private var PPS: CGFloat!
    
    override func loadView() {
        view = SoundWaveView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(_:))))
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressHeader(_:))))
    }
    
    @objc func loadAudio(url: URL, fps: Int, offsetFrames: CGFloat) {
        self.PPS = POINTS_PER_SECOND(FPS: fps)
        //
        self.audioOffset = offsetFrames * FRAME_HEIGHT
        (view as? SoundWaveView)?.audioOffset = self.audioOffset
        // Update duration
        let audioPlayer = try! AVAudioPlayer(contentsOf: url)
        let audioDuration: TimeInterval = audioPlayer.duration
        // Points height
        let height = self.PPS * CGFloat(audioDuration)
        (view as? SoundWaveView)?.height = height
        // Get values
        let audioFile = try! AVAudioFile(forReading: url)
        self.getDataArray(withAudioFile: audioFile, count: Int(height / WAVE_STEP)) { (values) in
//            let maxValue = values.max() ?? 1.0
//            let adjustedValues = values.map({ $0 / maxValue })
            DispatchQueue.main.async {
                (self.view as? SoundWaveView)?.values = values
            }
        }
    }
    
    @objc func updateScrollOffset(_ scrollOffset: CGFloat) {
        self.scrollOffset = scrollOffset
        (view as? SoundWaveView)?.scrollOffset = scrollOffset
        view.setNeedsDisplay()
    }
    
    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
        guard !isLocked else {
            return
        }
        
        let translationY = recognizer.translation(in: self.view).y
        recognizer.setTranslation(.zero, in: self.view)
        self.audioOffset += translationY
        (view as? SoundWaveView)?.audioOffset += translationY
        
        delegate?.didChangeOffset(to: self.audioOffset / FRAME_HEIGHT)
    }
    
    @objc func longPressHeader(_ recognizer: UILongPressGestureRecognizer) {
        guard !isLocked || titleRect.contains(recognizer.location(in: view)) else {
            return
        }
        
        guard recognizer.state == .began else {
            return
        }
        
        delegate?.didLongPressSoundHeader(view: view, rect: titleRect)
    }
    
    // MARK: - Processing
    
    private func getDataArray(withAudioFile audioFile: AVAudioFile, count numberOfReadLoops: Int, completionHandler: @escaping (_ success: [Float]) -> Void) {
        let audioFilePFormat = audioFile.processingFormat
        let audioFileLength = audioFile.length
        // get numberOfReadLoops value
        let frameSizeToRead = Int(audioFileLength) / numberOfReadLoops
        DispatchQueue.global(qos: .userInitiated).async {
            var returnArray : [Float] = []
            for i in 0..<numberOfReadLoops {
                audioFile.framePosition = AVAudioFramePosition(i * frameSizeToRead)
                if let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFilePFormat, frameCapacity: AVAudioFrameCount(frameSizeToRead)) {
                    try! audioFile.read(into: audioBuffer, frameCount: AVAudioFrameCount(frameSizeToRead))
                    let channelData = audioBuffer.floatChannelData![0]
                    let arr = Array(UnsafeBufferPointer(start: channelData, count: frameSizeToRead))
                    let positiveArray = arr.map({ abs($0) })
                    let sum = positiveArray.reduce(0, +)
                    
                    let value = (sum * 2) / Float(frameSizeToRead)
                    
                    returnArray.append(value)
                }
            }
            completionHandler(returnArray)
        }
    }
    
}
