//
//  ViewController.swift
//  OpenGL ES-09
//
//  Created by Mac on 2022/8/18.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVPlayerItemOutputPullDelegate {
    
    var displayLink: CADisplayLink!
    var player: AVPlayer!
    var videoOutput: AVPlayerItemVideoOutput! //output
    var mProcessQueue: DispatchQueue!
    var reader: DDAssetReader!


    @IBOutlet var renderView: DDView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "test.mov", ofType: nil)!)
        self.reader = DDAssetReader(videoURL)
        
        let item = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: item)
        let asset: AVAsset = item.asset
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            if asset.statusOfValue(forKey: "tracks", error: nil) == AVKeyValueStatus.loaded {
                let tracks = asset.tracks(withMediaType: AVMediaType.video)
                if tracks.count > 0 {
                    // Choose the first video track.
                    let videoTrack: AVAssetTrack = tracks.first!
                    videoTrack.loadValuesAsynchronously(forKeys: ["preferredTransform"]) {
                        if videoTrack.statusOfValue(forKey: "preferredTransform", error: nil) == AVKeyValueStatus.loaded {
                            let preferredTransform: CGAffineTransform = videoTrack.preferredTransform
                            let preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a)
                            NSLog("preferredRotation ----> \(preferredRotation)")

                            DispatchQueue.main.async {
                                item.add(self.videoOutput)
                                self.player.replaceCurrentItem(with: item)
                                self.videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: 0.03)
                                self.player.play()
                            }
                        }
                    }
                }
            }
        }

        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item, queue: OperationQueue.main) { noti in
            self.player.currentItem?.seek(to: CMTime.zero, completionHandler: { suc in

            })
        }

        mProcessQueue = DispatchQueue(label: "mProcessQueue")

        //kCVPixelFormatType_32BGRA
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        videoOutput.setDelegate(self, queue: mProcessQueue)

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidUpdate(_:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
        displayLink.preferredFramesPerSecond = 30
        displayLink.isPaused = true
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }

    
    //MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    @objc func displayLinkDidUpdate(_ sender: CADisplayLink) {
        var outputItemTime: CMTime = .invalid

        // Calculate the nextVsync time which is when the screen will be refreshed next.
        let nextVSync: CFTimeInterval = sender.timestamp + sender.duration
        outputItemTime = videoOutput.itemTime(forHostTime: nextVSync)

        if videoOutput.hasNewPixelBuffer(forItemTime: outputItemTime) {
            var pixelBuffer: CVPixelBuffer?
            pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: outputItemTime, itemTimeForDisplay: nil)
            self.renderView.renderBuffer(pixelBuffer: pixelBuffer)
        }
        
//        if let sampleBuffer = self.reader.readBuffer() {
//            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//            self.renderView.renderBuffer(pixelBuffer: pixelBuffer!)
//        }
    }
    
    //MARK: - AVPlayerItemOutputPullDelegate
    func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
        // Restart display link.
        displayLink.isPaused = false
    }
    
}

