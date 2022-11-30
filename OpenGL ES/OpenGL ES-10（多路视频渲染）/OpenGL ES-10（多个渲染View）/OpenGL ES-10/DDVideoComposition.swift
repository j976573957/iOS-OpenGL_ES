//
//  DDVideoComposition.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/22.
//

import UIKit
import CoreMedia
import AVFoundation

class DDVideoComposition: NSObject {
    
    var clips: [AVURLAsset] = []
    var clipTimeRanges: [CMTimeRange] = []
    var transitionDuration: CMTime = .zero
    
    var composition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var audioMix: AVMutableAudioMix!

    var playerItem: AVPlayerItem!
    
    func buildTransitionComposition() {
        let composition = AVMutableComposition()
        var nextClipStartTime: CMTime = .zero
        
        // 确保最后合并后的视频，变换长度不会超过最小长度的一半
        var transitionDuration: CMTime = self.transitionDuration
        for i in 0..<self.clips.count {
            let clipTimeRange = self.clipTimeRanges[i]
            if (!clipTimeRange.isEmpty) {
                var halfClipDuration: CMTime = clipTimeRange.duration
                halfClipDuration.timescale *= 2
                transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration)
            }
        }
        
        // 添加两条视频视频轨道 和 两条音频视频轨道
        var compositionVideoTracks: [AVMutableCompositionTrack] = []
        var compositionAudioTracks: [AVMutableCompositionTrack] = []
        
        // 添加视频轨道0
        let videoTracks0 = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        compositionVideoTracks.append(videoTracks0!)
        // 添加视频轨道1
        let videoTracks1 = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        compositionVideoTracks.append(videoTracks1!)
       
        // 添加音频轨道0
        let audioTracks0 = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        compositionAudioTracks.append(audioTracks0!)
        // 添加音频轨道1
        let audioTracks1 = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        compositionAudioTracks.append(audioTracks1!)
        
    }

}
