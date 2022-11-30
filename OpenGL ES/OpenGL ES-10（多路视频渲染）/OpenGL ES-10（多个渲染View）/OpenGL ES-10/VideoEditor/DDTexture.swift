//
//  DDTexture.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/9/23.
//

import Foundation
import AVFoundation

class DDTexture {
    var texture: CVOpenGLESTexture!
    let pixelBuffer: CVPixelBuffer
    var width: Int {
        get {
            return CVPixelBufferGetWidth(pixelBuffer)
        }
    }
    var height: Int {
        get {
            return CVPixelBufferGetHeight(pixelBuffer)
        }
    }
    
    init(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
    }
}
