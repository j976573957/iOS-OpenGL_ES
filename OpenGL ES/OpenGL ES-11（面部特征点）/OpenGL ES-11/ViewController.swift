//
//  ViewController.swift
//  OpenGL ES-11
//
//  Created by Mac on 2022/8/18.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var mCaptureSession: AVCaptureSession! //负责输入和输出设备之间的数据传递
    var mCaptureDeviceInput: AVCaptureDeviceInput! //负责从AVCaptureDevice获得输入数据
    var mCaptureDeviceOutput: AVCaptureVideoDataOutput! //output
    var mProcessQueue: DispatchQueue!


    @IBOutlet var renderView: DDView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mCaptureSession = AVCaptureSession()
        self.mCaptureSession.sessionPreset = AVCaptureSession.Preset.high
        
        mProcessQueue = DispatchQueue(label: "mProcessQueue")
        
        var inputCamera: AVCaptureDevice!
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            if (device.position == AVCaptureDevice.Position.front)
            {
                inputCamera = device;
            }
        }
        
        self.mCaptureDeviceInput = try? AVCaptureDeviceInput(device: inputCamera)//[[ alloc] initWithDevice:inputCamera error:nil];
        
        if (self.mCaptureSession.canAddInput(self.mCaptureDeviceInput)) {
            self.mCaptureSession.addInput(self.mCaptureDeviceInput)
        }

        
        self.mCaptureDeviceOutput = AVCaptureVideoDataOutput()
        self.mCaptureDeviceOutput.alwaysDiscardsLateVideoFrames = false
        

        //kCVPixelFormatType_32BGRA  &  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        self.mCaptureDeviceOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA]
        self.mCaptureDeviceOutput.setSampleBufferDelegate(self, queue: self.mProcessQueue)
        
        if (self.mCaptureSession.canAddOutput(self.mCaptureDeviceOutput)) {
            self.mCaptureSession.addOutput(self.mCaptureDeviceOutput)
        }
        
        let connection: AVCaptureConnection = self.mCaptureDeviceOutput.connection(with: AVMediaType.video)!
        connection.isVideoMirrored = inputCamera.position == .front
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        setupFacepp()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.mCaptureSession.startRunning()
    }

    func setupFacepp() {
        FaceDetector.shareInstance().sampleBufferOrientation = .noRatation
        FaceDetector.shareInstance().sampleType = FaceDetectorSampleType.camera
        FaceDetector.shareInstance().auth()
    }
    
    //MARK: - 事件
    
    @IBAction func drawLandMark(_ sender: UISwitch) {
        renderView.drawLandMark = sender.isOn
    }
    @IBAction func bigEyeValueDidChanged(_ sender: UISlider) {
        renderView.bigEyeDelta = sender.value
    }
    
    @IBAction func thinFaceValueDidChanged(_ sender: UISlider) {
        renderView.thinFaceDelta = sender.value
    }
    
    //MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            self.renderView.renderBuffer(pixelBuffer: pixelBuffer!)
            
            if !FaceDetector.shareInstance().isWorking {
                DispatchQueue.main.async {
                    var detectSampleBuffer: CMSampleBuffer?
                    CMSampleBufferCreateCopy(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleBufferOut: &detectSampleBuffer)
                    if let detectSampleBuffer = detectSampleBuffer {
                        FaceDetector.shareInstance().getLandmarksFrom(detectSampleBuffer)
                    }
                }
            }
        }
    }
    
}

