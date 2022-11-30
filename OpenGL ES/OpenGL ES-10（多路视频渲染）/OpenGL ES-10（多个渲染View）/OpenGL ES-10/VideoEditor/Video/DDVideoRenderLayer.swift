//
//  DDVideoRenderLayer.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/26.
//

import Foundation
import AVFoundation

class DDVideoRenderLayer {
    let renderLayer: DDRenderLayer
    var trackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    var timeRangeInTimeline: CMTimeRange
    var preferredTransform: CGAffineTransform = CGAffineTransform.identity
    
    init(renderLayer: DDRenderLayer) {
        self.renderLayer = renderLayer
        self.timeRangeInTimeline = renderLayer.timeRange
    }
    
    ///添加视频轨道
    func addVideoTrack(to composition: AVMutableComposition, preferredTrackID: CMPersistentTrackID) {
        guard let source = renderLayer.source else { return }
        guard let assetTrack = source.tracks(for: .video).first else { return }
        trackID = preferredTrackID
        preferredTransform = assetTrack.preferredTransform
        
        let compositionTrack: AVMutableCompositionTrack? = {
            if let compositionTrack = composition.track(withTrackID: preferredTrackID) {
                return compositionTrack
            }
            return composition.addMutableTrack(withMediaType: .video, preferredTrackID: preferredTrackID)
        }()
        
        if let compositionTrack = compositionTrack {
            do {
                try compositionTrack.insertTimeRange(source.selectdTimeRange, of: assetTrack, at: timeRangeInTimeline.start)
            } catch {
                // TODO: handle Error
            }
        }
    }
    
}
