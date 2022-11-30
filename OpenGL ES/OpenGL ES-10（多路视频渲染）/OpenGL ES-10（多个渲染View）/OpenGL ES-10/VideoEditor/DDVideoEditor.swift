//
//  DDVideoEditor.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/23.
//

import UIKit
import AVFoundation

class DDVideoEditor {
    private(set) var renderComposition: DDRenderComposition
    private var videoRenderLayers: [DDVideoRenderLayer] = []
//    private var audioRenderLayersInTimeline: [au]
    
    private var composition: AVComposition? //包含多个轨道的媒体信息
    private var videoComposition: AVMutableVideoComposition? //视频操作指令集合
    private var audioMix: AVAudioMix?
    
    //MARK: - Public
    init(renderComposition: DDRenderComposition) {
        self.renderComposition = renderComposition
    }
    
    //MARK: - Private
    private func makeCompostion() -> AVComposition {
        let composition = AVMutableComposition()
        self.composition = composition
        
        // 增加轨道ID
        var increasementTrackID: CMPersistentTrackID = 0
        func increaseTrackID() -> Int32 {
            let trackID = increasementTrackID + 1
            increasementTrackID = trackID
            return trackID
        }
        
        // 第 1 步：添加视频轨道
        // 生成视频轨道 ID。 此内联方法用于子步骤。
        // 如果与之前的一些没有交集，则可以重用track ID，否则增加一个ID。
        var videoTrackIDInfo: [CMPersistentTrackID : CMTimeRange] = [:]
        func videoTrackID(for layer: DDVideoRenderLayer) -> CMPersistentTrackID {
            var videoTrackID: CMPersistentTrackID?
            for (trackID, timeRange) in videoTrackIDInfo {
                if layer.timeRangeInTimeline.start > timeRange.end {
                    videoTrackID = trackID
                    videoTrackIDInfo[trackID] = layer.timeRangeInTimeline
                    break
                }
            }
            
            if let videoTrackID = videoTrackID {
                return videoTrackID
            } else {
                let videoTrackID = increaseTrackID()
                videoTrackIDInfo[videoTrackID] = layer.timeRangeInTimeline
                return videoTrackID
            }
        }
        
        
        // 子步骤 2：将时间轴中的所有 VideoRenderLayer 轨道添加到 composition。
        // 计算子步骤 3 的最小开始时间和最大结束时间。
        var videoRenderLayersInTimeline: [DDVideoRenderLayer] = []
        videoRenderLayers.forEach { videoRenderLayer in
            videoRenderLayersInTimeline.append(videoRenderLayer)
        }
        
        let mininmumStartTime = videoRenderLayersInTimeline.first?.timeRangeInTimeline.start
        var maximumEndTime = videoRenderLayersInTimeline.first?.timeRangeInTimeline.end
        videoRenderLayersInTimeline.forEach { videoRenderLayer in
            if videoRenderLayer.renderLayer.source?.tracks(for: .video).first != nil {
                let trackID = videoTrackID(for: videoRenderLayer)
                videoRenderLayer.addVideoTrack(to: composition, preferredTrackID: trackID)
            }
            
            if maximumEndTime! < videoRenderLayer.timeRangeInTimeline.end {
                maximumEndTime = videoRenderLayer.timeRangeInTimeline.end
            }
        }
        
        
        // 第 2 步：添加音频轨道
        //子步骤2:从时间轴添加音轨到合成。
        //因为AVAudioMixInputParameters只对应一个音轨ID，所以音轨ID不会被重用。一个音频层对应一个音轨ID。
        
        
        
        return composition
    }
}
