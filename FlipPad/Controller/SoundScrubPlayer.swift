//
//  SoundScrubPlayer.swift
//  FlipPad
//
//  Created by Alex Vihlayew on 3/27/21.
//  Copyright © 2021 Alex. All rights reserved.
//

import UIKit

@objc class SoundScrubPlayer: NSObject {
    
    private let audioQueue = DispatchQueue(label: "scubSound", qos: .userInteractive)
 
    private var forwardAudioPlayer: AVAudioPlayer?
    private var backwardAudioPlayer: AVAudioPlayer?
        
    @objc init(audioData: Data) {
        super.init()
        
        let outputUrl = SoundScrubPlayer.reverse(data: audioData)
        
        audioQueue.async { [weak self] in
            self?.forwardAudioPlayer = try? AVAudioPlayer(data: audioData)
            self?.forwardAudioPlayer?.enableRate = true
            self?.forwardAudioPlayer?.numberOfLoops = -1
            self?.forwardAudioPlayer?.prepareToPlay()
            
            if let outputUrl = outputUrl {
                self?.backwardAudioPlayer = try? AVAudioPlayer(contentsOf: outputUrl)
                self?.backwardAudioPlayer?.enableRate = true
                self?.backwardAudioPlayer?.numberOfLoops = -1
                self?.backwardAudioPlayer?.prepareToPlay()
            }
        }
    }
    
    @objc func scrubUpdated(velocity: CGFloat, audioTime: CGFloat) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
//        print("!!! scrubUpdated, rate:", velocity, "time:", audioTime)
        
        self.currentlyPlayingIndex = nil
        
        audioQueue.async { [weak self] in
            self?.frameStopTimer = nil
            
            // If not in range - stop
            guard let forwardAudioPlayer = self?.forwardAudioPlayer, (0.0...forwardAudioPlayer.duration).contains(TimeInterval(audioTime)) else {
                self?.stopPlayback()
                return
            }
            
            if velocity >= 0.0 {
                // Forward
                if velocity > 1.0 {
                    self?.scrubFastEnough(activePlayer: forwardAudioPlayer, inactivePlayer: self?.backwardAudioPlayer, velocity: velocity, audioTime: audioTime)
                }
            } else {
                // Backward
                if velocity < -1.0 {
                    self?.scrubFastEnough(activePlayer: self?.backwardAudioPlayer, inactivePlayer: forwardAudioPlayer, velocity: -velocity, audioTime: audioTime)
                }
            }
        }
        
        self.perform(#selector(stop), with: nil, afterDelay: TimeInterval(0.15))
    }
    
    private var currentlyPlayingIndex: Int?
    private var frameStopTimer: DispatchSourceTimer?
    
    @objc func scrubSlowlyUpdated(velocity: CGFloat, frameIndex: Int, frameStartAudioTime: CGFloat, frameDuration: CGFloat) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
         
//        print("!!! scrubSlowlyUpdated, index:", frameIndex, frameStartAudioTime, frameDuration, velocity)
        
        guard frameIndex != self.currentlyPlayingIndex else {
            return
        }
        self.currentlyPlayingIndex = frameIndex
                
        // If not in range - stop
        guard let forwardAudioPlayer = forwardAudioPlayer, (0.0...forwardAudioPlayer.duration).contains(TimeInterval(frameStartAudioTime)) else {
            self.stop()
            return
        }
        
        audioQueue.async { [weak self] in
            self?.frameStopTimer = nil
            
            if velocity >= 0.0 {
                // Forward
                self?.scrubSlowly(activePlayer: self?.forwardAudioPlayer, inactivePlayer: self?.backwardAudioPlayer, audioTime: frameStartAudioTime)
            } else {
                // Backward
                self?.scrubSlowly(activePlayer: self?.backwardAudioPlayer, inactivePlayer: self?.forwardAudioPlayer, audioTime: frameStartAudioTime)
            }
            
            if let slf = self {
                slf.frameStopTimer = DispatchSource.makeTimerSource(queue: slf.audioQueue)
                slf.frameStopTimer?.setEventHandler(handler: slf.stopPlayback)
                slf.frameStopTimer?.schedule(deadline: .now() + .milliseconds(Int(frameDuration * 1000)) + .milliseconds(100))
                slf.frameStopTimer?.resume()
            }
        }
        
        self.perform(#selector(stop), with: nil, afterDelay: TimeInterval(0.3))
    }
    
    private func scrubSlowly(activePlayer: AVAudioPlayer?, inactivePlayer: AVAudioPlayer?, audioTime: CGFloat) {
        inactivePlayer?.stop()
        
        if let activePlayer = activePlayer {
            activePlayer.stop()
            
            activePlayer.currentTime = TimeInterval(audioTime)
            
            activePlayer.prepareToPlay()
            activePlayer.play()
            activePlayer.rate = 1.0
        }
    }
    
    private func scrubFastEnough(activePlayer: AVAudioPlayer?, inactivePlayer: AVAudioPlayer?, velocity: CGFloat, audioTime: CGFloat) {
        inactivePlayer?.stop()
        
        if let activePlayer = activePlayer {
            if !activePlayer.isPlaying {
                activePlayer.play()
            }
            activePlayer.rate = Float(velocity)
            
            if abs(activePlayer.currentTime - Double(audioTime)) > 0.25 {
                activePlayer.currentTime = TimeInterval(audioTime)
            }
        }
    }
    
    @objc func stop() {
        audioQueue.async { [weak self] in
            self?.stopPlayback()
        }
    }
    
    @objc func stopPlayback() {
        // Fragment stop timer
        self.frameStopTimer = nil
        // Players
        self.forwardAudioPlayer?.stop()
        self.backwardAudioPlayer?.stop()
    }
    
    // MARK: - Utilities
    
    private static func reverse(data audioData: Data) -> URL? {
        do {
            // Input
            let inputUrl = URL(fileURLWithPath: (NSTemporaryDirectory() + "/" + "input_reverse.m4a"))
            // Remove previous file
            if FileManager.default.fileExists(atPath: inputUrl.path) {
                try FileManager.default.removeItem(atPath: inputUrl.path)
            }
            // Create new file for input
            FileManager.default.createFile(atPath: inputUrl.path, contents: audioData, attributes: nil)
            
            let inFile: AVAudioFile = try AVAudioFile(forReading: inputUrl)
            let format: AVAudioFormat = inFile.processingFormat
            let frameCount: AVAudioFrameCount = UInt32(inFile.length)

            // Output
            let outputUrl = URL(fileURLWithPath: (NSTemporaryDirectory() + "/" + "reverse.m4a"))
            // Remove previous file
            if FileManager.default.fileExists(atPath: outputUrl.path) {
                try FileManager.default.removeItem(atPath: outputUrl.path)
            }
            
            let outSettings = [AVNumberOfChannelsKey: format.channelCount,
                                       AVSampleRateKey: format.sampleRate,
                                       AVLinearPCMBitDepthKey: 16,
                                       AVFormatIDKey: kAudioFormatMPEG4AAC] as [String : Any]
            let outFile: AVAudioFile = try AVAudioFile(forWriting: outputUrl, settings: outSettings)
            
            let forwardBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            let reverseBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            
            try inFile.read(into: forwardBuffer)
            let frameLength = forwardBuffer.frameLength
            reverseBuffer.frameLength = frameLength
            let audioStride = forwardBuffer.stride
            
            for channelIdx in 0..<forwardBuffer.format.channelCount {
                let forwardChannelData = forwardBuffer.floatChannelData?.advanced(by: Int(channelIdx)).pointee
                let reverseChannelData = reverseBuffer.floatChannelData?.advanced(by: Int(channelIdx)).pointee
                
                var reverseIdx: Int = 0
                for frameIdx in stride(from: Int(frameLength), to: 0, by: -1) {
                    let sample = forwardChannelData?.advanced(by: frameIdx * audioStride).pointee
                    reverseChannelData?.advanced(by: reverseIdx * audioStride).pointee = sample!
                    reverseIdx += 1
                }
            }
            
            try outFile.write(from: reverseBuffer)
            
            return outputUrl
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
}
