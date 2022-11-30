//
//  DDsource.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/23.
//

import Foundation
import AVFoundation

protocol DDsource {
    var selectdTimeRange: CMTimeRange { get set}
    var duration: CMTime { get set }
    var isLoaded: Bool { get set }
    
    func load(completion: @escaping (NSError?) -> Void)
    func tracks(for type: AVMediaType) -> [AVAssetTrack] //AVAssetTrack:资源轨道，包括音频轨道和视频轨道
    func texture(at time: CMTime) -> DDTexture
    
}
