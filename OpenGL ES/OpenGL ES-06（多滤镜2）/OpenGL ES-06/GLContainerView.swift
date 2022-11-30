//
//  GLContainerView.swift
//  OpenGL ES-06
//
//  Created by Mac on 2022/8/19.
//

import UIKit
import AVFoundation

class GLContainerView: UIView {

    //图片
    var image: UIImage! {
        didSet {
            self.layoutRenderView()
            //渲染图片
            self.renderView.layoutGLViewWithImage(image)
        }
    }
    //色温值
    var colorTempValue: CGFloat = 0 {
        didSet {
            //glView获取色温
            self.renderView.temperature = colorTempValue
        }
    }
    //饱和度
    var saturationValue: CGFloat = 0 {
        didSet {
            //glView获取饱和度
            self.renderView.saturation = saturationValue
        }
    }
    
    var renderView: DDView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupRnderView()
    }
    

    //MARK: - Setup
   private func setupRnderView() {
        //获取GLView
       self.renderView = DDView(frame: self.bounds)
         //添加到self上
       self.addSubview(self.renderView)
    }

    //MARK: - Private
   private func layoutRenderView() {
        
        //获取图片尺寸
        let imageSize = self.image.size
        
        //Returns a scaled CGRect that maintains the aspect ratio specified by a CGSize within a bounding CGRect.
        //返回一个在Self.bounds范围的CGRect,根据imagaSize的一个纵横比
       let frame = AVMakeRect(aspectRatio: imageSize, insideRect: self.bounds)
       
        //修改glView的frame
        self.renderView.frame = frame
        
        //应用于视图的比例因子
        self.renderView.contentScaleFactor = imageSize.width / frame.size.width
    }

}
