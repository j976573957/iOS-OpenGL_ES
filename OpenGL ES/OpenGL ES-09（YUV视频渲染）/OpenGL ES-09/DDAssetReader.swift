//
//  DDAssetReader.swift
//  OpenGL ES-09
//
//  Created by LHR on 2022/9/11.
//

import UIKit
import AVFoundation

class DDAssetReader: NSObject {

    var readerVideoTrackOutput: AVAssetReaderTrackOutput!
    var assetReader: AVAssetReader!
    var videoUrl: URL!
    var lock: NSLock!
    
    init(_ url: URL) {
        super.init()
        videoUrl = url
        lock = NSLock()
        customInit()
    }
    
    func customInit() {
        let inputOptions = [AVURLAssetPreferPreciseDurationAndTimingKey : true]
        let inputAsset = AVURLAsset(url: videoUrl, options: inputOptions)
        inputAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            DispatchQueue.global().async {
                var error: NSError?
                let tracksStatus = inputAsset.statusOfValue(forKey: "tracks", error: &error)
                if (tracksStatus != AVKeyValueStatus.loaded) {
                    NSLog("error = \(error!)")
                    return
                }
                self.processWithAsset(inputAsset)
            }
        }
    }
    
    func processWithAsset(_ asset: AVAsset) {
        lock.lock()
        NSLog("processWithAsset")

        assetReader = try? AVAssetReader(asset: asset)
        
        let outputSettings = [String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        
        readerVideoTrackOutput = AVAssetReaderTrackOutput(track: asset.tracks(withMediaType: AVMediaType.video).first!, outputSettings: outputSettings)
        readerVideoTrackOutput.alwaysCopiesSampleData = false
        assetReader.add(readerVideoTrackOutput)

        
        if (assetReader.startReading() == false) {
            NSLog("Error reading from file at URL: %@", asset)
        }
        lock.unlock()
    }
    
    func readBuffer() -> CMSampleBuffer? {
        lock.lock()
        var sampleBuffer: CMSampleBuffer?
        
        if ((readerVideoTrackOutput) != nil) {
            sampleBuffer = readerVideoTrackOutput.copyNextSampleBuffer()
        }
        
        if ((assetReader != nil) && assetReader.status == AVAssetReader.Status.completed) {
            NSLog("customInit")
            readerVideoTrackOutput = nil
            assetReader = nil
            customInit()
        }
        
        lock.unlock()
        return sampleBuffer
    }
}
