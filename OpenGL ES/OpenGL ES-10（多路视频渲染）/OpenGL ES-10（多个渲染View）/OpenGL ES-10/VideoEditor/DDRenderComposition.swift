//
//  DDRenderComposition.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/23.
//

import Foundation
import UIKit
import CoreMedia

class DDRenderComposition {
    var backgroundColor: UIColor = .black
    
    var frameDuration: CMTime = CMTime(value: 1, timescale: 30)//1秒30帧
    var renderSize: CGSize = CGSize(width: 720, height: 1280)
    
    var layers: [DDRenderLayer] = []
}
