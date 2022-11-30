//
//  ViewController.swift
//  OpenGL ES-10
//
//  Created by Mac on 2022/8/18.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVPlayerItemOutputPullDelegate {
    
    var displayLink: CADisplayLink!
    var reader: DDAssetReader!
    var reader1: DDAssetReader!
    var reader2: DDAssetReader!
    var reader3: DDAssetReader!


    
    @IBOutlet var renderView1: DDView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "video1.MOV", ofType: nil)!)
        self.reader = DDAssetReader(videoURL)
        
        let videoURL1 = URL(fileURLWithPath: Bundle.main.path(forResource: "video2.MOV", ofType: nil)!)
        self.reader1 = DDAssetReader(videoURL1)
        
        let videoURL2 = URL(fileURLWithPath: Bundle.main.path(forResource: "video3.MOV", ofType: nil)!)
        self.reader2 = DDAssetReader(videoURL2)
        
        let videoURL3 = URL(fileURLWithPath: Bundle.main.path(forResource: "video4.MOV", ofType: nil)!)
        self.reader3 = DDAssetReader(videoURL3)

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate(_:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        displayLink.preferredFramesPerSecond = 30
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }

    
    //MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    @objc func displayLinkDidUpdate(_ sender: CADisplayLink) {
        
        if let sampleBuffer = self.reader.readBuffer() {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            self.renderView1.renderBuffer(pixelBuffer: pixelBuffer!, position: 1)
        }
        
//        if let sampleBuffer = self.reader1.readBuffer() {
//            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//            self.renderView1.renderBuffer(pixelBuffer: pixelBuffer!, position: 2)
//        }
//        
//        if let sampleBuffer = self.reader2.readBuffer() {
//            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//            self.renderView1.renderBuffer(pixelBuffer: pixelBuffer!, position: 3)
//        }
        
        if let sampleBuffer = self.reader3.readBuffer() {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            self.renderView1.renderBuffer(pixelBuffer: pixelBuffer!, position: 4)
        }
    }
    

    
}

