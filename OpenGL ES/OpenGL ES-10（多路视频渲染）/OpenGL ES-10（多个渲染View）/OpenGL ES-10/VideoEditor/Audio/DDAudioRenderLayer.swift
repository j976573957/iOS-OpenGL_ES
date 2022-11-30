//
//  DDAudioRenderLayer.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/10/8.
//

import AVFoundation

class DDAudioRenderLayer {
    let renderLayer: DDRenderLayer
    var trackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    var timeRangeInTimeline: CMTimeRange
    var preferredTransform: CGAffineTransform = CGAffineTransform.identity
    
    
    init(renderLayer: DDRenderLayer) {
        self.renderLayer = renderLayer
        self.timeRangeInTimeline = renderLayer.timeRange
    }
    
    func addAudioTrack(to composition: AVMutableComposition, preferredTrackID: CMPersistentTrackID) {
        guard let source = renderLayer.source else { return }
        guard let assetTrack = source.tracks(for: .audio).first else { return }
        
        let compositionTrack: AVMutableCompositionTrack? = {
            if let compositionTrack = composition.track(withTrackID: preferredTrackID) {
                return compositionTrack
            }
            return composition.addMutableTrack(withMediaType: .audio, preferredTrackID: preferredTrackID)
        }()
        
        if let compositionTrack = compositionTrack {
            do {
                try compositionTrack.insertTimeRange(source.selectdTimeRange, of: assetTrack, at: timeRangeInTimeline.start)
            } catch {
                // TODO: handle Error
            }
        }
    }
    
    func makeAudioTapProcessor() -> MTAudioProcessingTap? {
        guard renderLayer.canBeConvertedToAudioRenderLayer() else { return nil }
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: nil,
            unprepare: nil,
            process: tapProcess)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        let status = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        if status != noErr {
            print("Failed to create audio processing tap")
        }
        return tap?.takeRetainedValue()
    }
    
    //MARK: - Private
    private func processAudio(_ bufferListInOut: UnsafeMutablePointer<AudioBufferList>, timeRange: CMTimeRange) {
        guard timeRange.duration.isValid else {
            return
        }
        if timeRangeInTimeline.intersection(timeRange).isEmpty {
            return
        }
        
//        let 
    }
    
    // MARK: - MTAudioProcessingTapCallbacks
    private let tapInit: MTAudioProcessingTapInitCallback = { (tap, clientInfo, tapStorageOut) in
        tapStorageOut.pointee = clientInfo
    }
    
    let tapFinalize: MTAudioProcessingTapFinalizeCallback = { (tap) in
        Unmanaged<DDAudioRenderLayer>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release()
    }
    
    private let tapProcess: MTAudioProcessingTapProcessCallback = { (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        var timeRange: CMTimeRange = CMTimeRange.zero
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, &timeRange, numberFramesOut)
        if status != noErr {
            print("Failed to get source audio")
            return
        }
        
        let audioRenderLayer = Unmanaged<DDAudioRenderLayer>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
//        audioRenderLayer.pro
    }
    
}


extension DDRenderLayer {
    func canBeConvertedToAudioRenderLayer() -> Bool {
        return source?.tracks(for: .audio).first != nil
    }
}
