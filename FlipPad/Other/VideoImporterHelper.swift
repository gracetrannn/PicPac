//
//  Video.swift
//  FlipPad
//
//  Created by Alex on 1/21/20.
//  Copyright © 2020 DigiCel. All rights reserved.
//

import Foundation
import AVFoundation

@objc class VideoImporterHelper: NSObject {
    
    private var asset: AVAsset
    private var fps: Int
        
    private var frameTimes = [NSValue]()
    
    @objc init(_ url: NSURL, fps: Int) {
        self.asset = AVAsset(url: url as URL)
        self.fps = fps
        
        super.init()
        
        let videoTrack = self.asset.tracks.first(where: { $0.mediaType == .video })!
        
        let videoDuration = videoTrack.asset!.duration
        let timeValue = videoDuration.value
        let timeScale = videoDuration.timescale
        let videoDurationSeconds = Double(videoDuration.value) / Double(timeScale)
        let neededFramesCount = Int(videoDurationSeconds * Double(self.fps))
        let timeValuePerFrame = Int(Double(timeValue) / Double(neededFramesCount))
        
        for i in 0..<neededFramesCount {
            let value = CMTimeValue(timeValuePerFrame * i)
            let cmTime = CMTime(value: value, timescale: timeScale)
            frameTimes.append(NSValue(time: cmTime))
        }
    }
    
    @objc func expectedFramesCount() -> Int {
        frameTimes.count
    }
    
    // Image, current index, total
    @objc func getFrames(limit: Int, progressHandler nextFrame: @escaping (UIImage, Int, Int) -> Void) {
        let generator = AVAssetImageGenerator(asset: self.asset)
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.appliesPreferredTrackTransform = true
        
        let frameTimes = Array(self.frameTimes[0..<limit])
        
        for (index, time) in frameTimes.enumerated() {
            autoreleasepool {
                let image = try? generator.copyCGImage(at: time.timeValue, actualTime: nil)
                nextFrame(UIImage(cgImage: image!), index + 1, frameTimes.count)
            }
        }
    }
    
    @objc func extractAudio(completion: @escaping (Data?) -> Void) {
        let composition = AVMutableComposition()
        do {
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
                completion(nil)
                return
            }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                completion(nil)
                return
            }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
        }
        
        let outputPath = NSTemporaryDirectory() + UUID().uuidString + ".m4a"
        let outputUrl = URL(fileURLWithPath: outputPath)
 
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        exportSession?.outputURL = outputUrl
        exportSession?.outputFileType = AVFileType(rawValue: "com.apple.m4a-audio")

        exportSession?.exportAsynchronously(completionHandler: {
            let data = try? Data(contentsOf: outputUrl)
            completion(data)
        })
    }
}

