//
//  DDRenderLayer.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/23.
//

import Foundation
import CoreMedia

class DDRenderLayer {
    var timeRange: CMTimeRange
    let source: DDsource?
    
    public init(timeRange: CMTimeRange, source: DDsource? = nil) {
        self.timeRange = timeRange
        self.source = source
    }
}
