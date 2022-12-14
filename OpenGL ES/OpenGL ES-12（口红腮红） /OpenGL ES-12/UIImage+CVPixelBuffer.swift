//
//  UIImage+CVPixelBuffer.swift
//  OpenGL ES-12
//
//  Created by Mac on 2022/11/23.
//

import Foundation

//MARK: - UIImage & CVPixelBuffer 转换
extension UIImage {
    
    /// 重绘图片大小
    func resizedImage(outputSize: CGSize) -> UIImage? {
        if size == outputSize {
            return self
        }else {
            UIGraphicsBeginImageContext(outputSize)
//            UIGraphicsBeginImageContextWithOptions(outputSize, false, 0.0)
            draw(in: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let newImage = scaledImage else {
                return nil
            }
            return newImage
        }
    }
    
    /// UIImage -> CVPixelBuffer
    func imageToPixelBuffer(outputSize: CGSize) -> CVPixelBuffer? {
        
        let inputImage: UIImage = self
        var pixelBuffer: CVPixelBuffer? = nil
        guard let cgImage: CGImage = inputImage.cgImage else {
            return pixelBuffer
        }
        /// 分配内存，创建CVPixelBuffer
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(outputSize.width), Int(outputSize.height), kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        if status == kCVReturnSuccess, let pixelBuffer = pixelBuffer {
            /// 写入数据
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                    width: Int(outputSize.width),
                                    height: Int(outputSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return pixelBuffer
        }
        return pixelBuffer
    }
    
    /// CVPixelBuffer -> UIImage
    class func pixelBufferToImage(pixelBuffer: CVPixelBuffer, outputSize: CGSize? = nil) -> UIImage? {
//        let type = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
            let imageRef = context.makeImage() else
        {
                return nil
        }
        
        let newImage = outputSize != nil ? UIImage(cgImage: imageRef, scale: 1, orientation: UIImage.Orientation.up).resizedImage(outputSize: outputSize!) : UIImage(cgImage: imageRef, scale: 1, orientation: UIImage.Orientation.up)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return newImage
    }
    
}
