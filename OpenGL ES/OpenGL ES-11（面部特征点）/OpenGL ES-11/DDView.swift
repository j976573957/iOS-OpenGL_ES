//
//  DDView.swift
//  OpenGL ES-02
//
//  Created by Mac on 2022/8/18.
//

import UIKit
import OpenGLES.ES2
import AVFoundation

/*
 不采用GLKBaseEffect, 使用编译链接自定义着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
 思路：
     1.设置图层
     2.设置图形上下文
     3.设置渲染缓冲区（renderBuffer）
     4.设置帧缓冲区（frameBuffer）
     5.编译、链接着色器（shader）
     6.设置VBO (Vertex Buffer Objects)
     7.设置纹理
     8.渲染
 */

let standardVertex: [GLfloat] = [
    1.0,  -1.0, 0.0,     //右下
    -1.0,  1.0, 0.0,     // 左上
    -1.0, -1.0, 0.0,     // 左下

    1.0,   1.0, 0.0,     // 右上
    -1.0,  1.0, 0.0,     // 左上
    1.0,  -1.0, 0.0,     // 右下
]



let standardFragment: [GLfloat] = [
    1.0, 0.0, //右下
    0.0, 1.0, // 左上
    0.0, 0.0, // 左下
    
    1.0, 1.0, // 右上
    0.0, 1.0, // 左上
    1.0, 0.0  // 右下
]

let standardVerticalInvertFragment: [GLfloat] = [
    //上下翻转
    1.0, 1.0, //右下
    0.0, 0.0, // 左上
    0.0, 1.0, // 左下

    1.0, 0.0, // 右上
    0.0, 0.0, // 左上
    1.0, 1.0  // 右下
]

class DDView: UIView {
    
    //在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
    var myEagLayer: CAEAGLLayer!
    var myContext: EAGLContext!
    var renderBuffer: GLuint = 0
    var frameBuffer: GLuint = 0
    
    var displayProgram: GLuint = 0
    var renderProgram: GLuint = 0
    var faceProgram: GLuint = 0
    
    private var thinFaceProgram: GLuint = 0
    private var aspectRatioUniform: GLint = 0
    private var facePointsUniform: GLint = 0
    private var thinFaceDeltaUniform: GLint = 0
    private var bigEyeDeltaUniform: GLint = 0
    private var hasFaceUniform: GLint = 0
    private var inputTextureW: GLfloat = 0.0
    private var inputTextureH: GLfloat = 0.0
    var thinFaceDelta: Float = 0.0
    var bigEyeDelta: Float = 0.0
    
    var hasRender: Bool = false
    var texture: CVOpenGLESTexture? //kCVPixelFormatType_32BGRA
    var textureCache: CVOpenGLESTextureCache?
    
    var originalTexture: GLuint = 0
    var facePointTexture: GLuint = 0
    var facePointFrameBuffer: GLuint = 0
    var thinFaceTexture: GLuint = 0
    var thinFaceFrameBuffer: GLuint = 0
    var drawLandMark: Bool = true
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if hasRender { return }
        //1.设置图层
        setupLayer()
        
        //2.设置上下文
        setupContext()
        
        //3.设置RenderBuffer
        setupRenderBuffer()
        
        //4.设置FrameBuffer
        setupFrameBuffer()
        
        //5.编译、链接着色器（shader）
        displayProgram = DDProgram("shaderv.vsh", "fragmentShader.fsh").program
        renderProgram = DDProgram("shaderv.vsh", "shaderf.fsh").program
        faceProgram = DDProgram("drawLandmarkShaderv.vsh", "drawLandmarkShaderf.fsh").program
        thinFaceProgram = DDProgram("thinFaceShaderv.vsh", "thinFaceShaderf.fsh").program
        
        //6.设置VBO (Vertex Buffer Objects)
        
        //7.OpenGLESTextureCache
        let cacheResult: CVReturn = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, self.myContext, nil, &textureCache)
        if (cacheResult != kCVReturnSuccess) {
            NSLog("CVOpenGLESTextureCacheCreate fail %d", cacheResult)
        }
        
        //设置纹理
        setupFacePointTexture()
        setupThinFaceTexture()
        glActiveTexture(GLenum(GL_TEXTURE1))
        //生成纹理标记
        glGenTextures(1, &originalTexture)
        //绑定纹理
        glBindTexture(GLenum(GL_TEXTURE_2D), originalTexture)
        
        //8.渲染
//        renderLayer()
        
       
        
        hasRender = true
    }
    
    //1.设置图层
    func setupLayer() {
        //给图层开辟空间
        /*
         重写layerClass，将DDView返回的图层从CALayer替换成CAEAGLLayer
         */
        myEagLayer = (self.layer as! CAEAGLLayer)
        
        //设置放大倍数
        self.contentScaleFactor = UIScreen.main.scale
       
        //CALayer 默认是透明的，必须将它设为不透明才能将其可见。
        self.layer.isOpaque = true
        
        //设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
        /*
         kEAGLDrawablePropertyRetainedBacking                          表示绘图表面显示后，是否保留其内容。这个key的值，是一个通过NSNumber包装的bool值。如果是false，则显示内容后不能依赖于相同的内容，ture表示显示后内容不变。一般只有在需要内容保存不变的情况下，才建议设置使用,因为会导致性能降低、内存使用量增减。一般设置为flase.
         
        kEAGLDrawablePropertyColorFormat
             可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
             kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
             kEAGLColorFormatRGB565：16位RGB的颜色，
             kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
         
         
         */
        myEagLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : false, kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8]
    }
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }

    //2.设置上下文
    func setupContext() {
        //创建上下文 指定OpenGL ES 渲染API版本，我们使用2.0
        if let context = EAGLContext(api: .openGLES2) {
            //设置图形上下文
            EAGLContext.setCurrent(context)
            myContext = context
        } else {
            print("Create context failed!")
        }
    }
    
    
    //3.设置RenderBuffer
    func setupRenderBuffer() {
        //1.定义一个缓存区
        var buffer: GLuint = 0
        //2.申请一个缓存区标识符
        glGenRenderbuffers(1, &buffer)
        //3.将标识符绑定到GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), buffer)
        
        renderBuffer = buffer
        
        //frame buffer仅仅是管理者，不需要分配空间；render buffer的存储空间的分配，对于不同的render buffer，使用不同的API进行分配，而只有分配空间的时候，render buffer句柄才确定其类型
        
        //renderBuffer渲染缓存区分配存储空间
        myContext.renderbufferStorage(Int(GL_RENDERBUFFER), from: myEagLayer)
    }
    
    //4.设置FrameBuffer
    func setupFrameBuffer() {
        //1.定义一个缓存区
        var buffer: GLuint = 0
        //2.申请一个缓存区标志
        glGenFramebuffers(1, &buffer)
        //3.将标识符绑定到GL_FRAMEBUFFER
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), buffer)
        //4.
        frameBuffer = buffer
        
        //生成空间之后，则需要将renderbuffer跟framebuffer进行绑定，调用glFramebufferRenderbuffer函数进行绑定，后面的绘制才能起作用
        //5.将_renderBuffer 通过glFramebufferRenderbuffer函数绑定到GL_COLOR_ATTACHMENT0上。
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderBuffer)
        
        //接下来，可以调用OpenGL ES进行绘制处理，最后则需要在EGALContext的OC方法进行最终的渲染绘制。这里渲染的color buffer,这个方法会将buffer渲染到CALayer上。- (BOOL)presentRenderbuffer:(NSUInteger)target;
    }
    
    ///10.设置纹理
    private func setupFacePointTexture() {
        //绑定纹理之前,激活纹理
        glActiveTexture(GLenum(GL_TEXTURE0))
        //申请纹理标记
        glGenTextures(1, &facePointTexture)
        //绑定纹理
        glBindTexture(GLenum(GL_TEXTURE_2D), facePointTexture)
        //将图片载入纹理
        /*
         glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels)
         参数列表:
         1.target,目标纹理
         2.level,一般设置为0
         3.internalformat,纹理中颜色组件
         4.width,纹理图像的宽度
         5.height,纹理图像的高度
         6.border,边框的宽度
         7.format,像素数据的颜色格式
         8.type,像素数据数据类型
         9.pixels,内存中指向图像数据的指针
         */
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(self.frame.size.width * self.contentScaleFactor), GLsizei(self.frame.size.height * self.contentScaleFactor), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), nil)
        //设置纹理参数
        //放大\缩小过滤
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        //申请_tempFramesBuffe标记
        glGenFramebuffers(1, &facePointFrameBuffer)
        //绑定FrameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), facePointFrameBuffer)
        
        //应用FBO渲染到纹理（glGenTextures），直接绘制到纹理中。glCopyTexImage2D是渲染到FrameBuffer->复制FrameBuffer中的像素产生纹理。glFramebufferTexture2D直接渲染生成纹理，做全屏渲染（比如全屏模糊）时比glCopyTexImage2D高效的多。
        /*
         glFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level)
         参数列表:
         1.target,GL_FRAMEBUFFER
         2.attachment,附着点名称
         3.textarget,GL_TEXTURE_2D
         4.texture,纹理对象
         5.level,一般为0
         */
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), facePointTexture, 0)
        
        //注意⚠️：打破之前的纹理绑定关系，使OpenGL的纹理绑定状态恢复到默认状态。
        glBindTexture(GLenum(GL_TEXTURE_2D), 0) //将2D纹理绑定到默认的纹理，一般用于打破之前的纹理绑定关系，使OpenGL的纹理绑定状态恢复到默认状态。
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)//将framebuffer绑定到默认的FBO处，一般用于打破之前的FBO绑定关系，使OpenGL的FBO绑定状态恢复到默认状态。
    }
    
    ///11.设置纹理
    private func setupThinFaceTexture() {
        //绑定纹理之前,激活纹理
        glActiveTexture(GLenum(GL_TEXTURE0))
        //申请纹理标记
        glGenTextures(1, &thinFaceTexture)
        //绑定纹理
        glBindTexture(GLenum(GL_TEXTURE_2D), thinFaceTexture)
        //将图片载入纹理
        /*
         glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels)
         参数列表:
         1.target,目标纹理
         2.level,一般设置为0
         3.internalformat,纹理中颜色组件
         4.width,纹理图像的宽度
         5.height,纹理图像的高度
         6.border,边框的宽度
         7.format,像素数据的颜色格式
         8.type,像素数据数据类型
         9.pixels,内存中指向图像数据的指针
         */
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(self.frame.size.width * self.contentScaleFactor), GLsizei(self.frame.size.height * self.contentScaleFactor), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), nil)
        //设置纹理参数
        //放大\缩小过滤
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        //申请_tempFramesBuffe标记
        glGenFramebuffers(1, &thinFaceFrameBuffer)
        //绑定FrameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), thinFaceFrameBuffer)
        
        //应用FBO渲染到纹理（glGenTextures），直接绘制到纹理中。glCopyTexImage2D是渲染到FrameBuffer->复制FrameBuffer中的像素产生纹理。glFramebufferTexture2D直接渲染生成纹理，做全屏渲染（比如全屏模糊）时比glCopyTexImage2D高效的多。
        /*
         glFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level)
         参数列表:
         1.target,GL_FRAMEBUFFER
         2.attachment,附着点名称
         3.textarget,GL_TEXTURE_2D
         4.texture,纹理对象
         5.level,一般为0
         */
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), thinFaceTexture, 0)
        
        //注意⚠️：打破之前的纹理绑定关系，使OpenGL的纹理绑定状态恢复到默认状态。
        glBindTexture(GLenum(GL_TEXTURE_2D), 0) //将2D纹理绑定到默认的纹理，一般用于打破之前的纹理绑定关系，使OpenGL的纹理绑定状态恢复到默认状态。
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)//将framebuffer绑定到默认的FBO处，一般用于打破之前的FBO绑定关系，使OpenGL的FBO绑定状态恢复到默认状态。
    }
    
    
    //设置纹理
    func renderBuffer(pixelBuffer: CVPixelBuffer) {
        if (self.textureCache != nil) {//注意⚠️：释放内存，要不然会卡住
            if texture != nil { texture = nil }
            CVOpenGLESTextureCacheFlush(self.textureCache!, 0)
        }

        // Create a CVOpenGLESTexture from the CVImageBuffer
        let frameWidth = CVPixelBufferGetWidth(pixelBuffer)
        let frameHeight = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        inputTextureW = GLfloat(frameWidth)
        inputTextureH = GLfloat(frameHeight)
        
        
        //法一：使用 CVOpenGLESTexture进行加载
        let ret: CVReturn = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                         textureCache!,
                                                                         pixelBuffer,
                                                                         nil,
                                                                         GLenum(GL_TEXTURE_2D),
                                                                         GL_RGBA,
                                                                         GLsizei(frameWidth),
                                                                         GLsizei(frameHeight),
                                                                         GLenum(GL_BGRA),
                                                                         GLenum(GL_UNSIGNED_BYTE),
                                                                         0,
                                                                         &texture);
        if ((ret) != 0) {
            NSLog("CVOpenGLESTextureCacheCreateTextureFromImage ret: %d", ret)
            /*
             ⚠️注意：error: -6683 是录制时配置的 kCVPixelBufferPixelFormatTypeKey 与获取的颜色格式不对应
             1、kCVPixelFormatType_32BGRA -->
             CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
             textureCache!,
             pixelBuffer,
             nil,
             GLenum(GL_TEXTURE_2D),
             GL_RGBA,
             GLsizei(frameWidth),
             GLsizei(frameHeight),
             GLenum(GL_BGRA),
             GLenum(GL_UNSIGNED_BYTE),
             0,
             &texture);

             */
            return
        }
        //将 texture 绑定到 GL_TEXTURE0
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(CVOpenGLESTextureGetTarget(texture!), CVOpenGLESTextureGetName(texture!))
        
        
        //法二：使用 glTexImage2D 方式加载
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
//        glBindTexture(GLenum(GL_TEXTURE_2D), originalTexture)
//        #warning("这里width 使用 bytesPerRow/4，请看 08 项目有写")
//        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(bytesPerRow/4), GLsizei(frameHeight), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(pixelBuffer))
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
        

        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        
        
        //绘制
        renderFacePoint()
        
    }
    
    //8.渲染到屏幕上
    private func displayRenderToScreen(_ texture: GLuint) {
        //注意⚠️：打破之前的纹理绑定关系，使OpenGL的纹理绑定状态恢复到默认状态。
        glBindTexture(GLenum(GL_TEXTURE_2D), 0) //将2D纹理绑定到默认的纹理，一般用于打破之前的纹理绑定关系，使OpenGL的纹理绑定状态恢复到默认状态。
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)//将framebuffer绑定到默认的FBO处，一般用于打破之前的FBO绑定关系，使OpenGL的FBO绑定状态恢复到默认状态。
        
        //设置清屏颜色
        glClearColor(0.0, 0.0, 0.0, 1.0)
        //清除屏幕
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        //1.设置视口大小
        let scale = self.contentScaleFactor
        glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
        
        //使用着色器
        glUseProgram(displayProgram)
        //绑定frameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)

#warning("注意⚠️：想要获取shader里面的变量，这里要记住要在glLinkProgram后面、后面、后面")
        //----处理顶点数据-------
        //将顶点数据通过renderProgram中的传递到顶点着色程序的position
        /*1.glGetAttribLocation,用来获取vertex attribute的入口的.
          2.告诉OpenGL ES,通过glEnableVertexAttribArray，
          3.最后数据是通过glVertexAttribPointer传递过去的。
         */
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
        let position = glGetAttribLocation(displayProgram, "position")

        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(position))

        //设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
//        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVertex)


        //----处理纹理数据-------
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
        let textCoord = glGetAttribLocation(displayProgram, "textCoordinate")

        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(textCoord))

        //3.设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
//        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVerticalInvertFragment)

        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        glUniform1i(glGetUniformLocation(self.displayProgram, "inputImageTexture"), 0) //单个纹理可以不用设置

        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
    
        if (EAGLContext.current() == myContext) {
            myContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
        }
        
    }
    
    //MARK: - 绘制面部特征点
    ///绘制面部特征点
    func renderFacePoint() {
        //MARK: - 1.绘制摄像头
        //使用着色器
        glUseProgram(renderProgram)
        //绑定frameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), facePointFrameBuffer)
        
        //设置清屏颜色
        glClearColor(0.0, 0.0, 0.0, 1.0)
        //清除屏幕
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        //1.设置视口大小
        let scale = self.contentScaleFactor
        glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
        
       

#warning("注意⚠️：想要获取shader里面的变量，这里要记住要在glLinkProgram后面、后面、后面")
        //----处理顶点数据-------
        //将顶点数据通过renderProgram中的传递到顶点着色程序的position
        /*1.glGetAttribLocation,用来获取vertex attribute的入口的.
          2.告诉OpenGL ES,通过glEnableVertexAttribArray，
          3.最后数据是通过glVertexAttribPointer传递过去的。
         */
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
        let position = glGetAttribLocation(renderProgram, "position")

        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(position))

        //设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
//        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVertex)


        //----处理纹理数据-------
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
        let textCoord = glGetAttribLocation(renderProgram, "textCoordinate")

        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(textCoord))

        //3.设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
//        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVerticalInvertFragment)

        
        //法一：使用 CVOpenGLESTexture进行加载，打开下面
        glActiveTexture(GLenum(GL_TEXTURE0))
        glUniform1i(glGetUniformLocation(self.renderProgram, "colorMap"), 0)
        
        //法二：使用 glTexImage2D 方式加载，打开下面
//        glActiveTexture(GLenum(GL_TEXTURE1))
//        glBindTexture(GLenum(GL_TEXTURE_2D), originalTexture)
//        glUniform1i(glGetUniformLocation(self.renderProgram, "colorMap"), 1) //单个纹理可以不用设置

        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        
        //MARK: - 2.绘制面部特征点
        if drawLandMark {
            //注意⚠️：不能清屏。否则看不到照相机画面
            //        glClearColor(0.0, 0.0, 0.0, 1.0)
            //清除屏幕
            //        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            //1.设置视口大小
            glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
            
            //使用着色器
            glUseProgram(faceProgram)
            
            for faceInfo in FaceDetector.shareInstance().faceModels {
                
                var tempPoint: [GLfloat] = [GLfloat].init(repeating: 0, count: faceInfo.landmarks.count * 3)
                var indices: [GLubyte] = [GLubyte].init(repeating: 0, count: faceInfo.landmarks.count)
                for i in 0..<faceInfo.landmarks.count {
                    let point = faceInfo.landmarks[i].cgPointValue
                    tempPoint[i*3+0] = GLfloat(point.x * 2 - 1)
                    tempPoint[i*3+1] = GLfloat(point.y * 2 - 1)
                    tempPoint[i*3+2] = 0.0
                    indices[i] = GLubyte(i)
                    
                }
                
                let position = glGetAttribLocation(faceProgram, "position")
                glEnableVertexAttribArray(GLuint(position))
                //这种方式得先把顶点数据提交到GPU
                //            glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 3), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))
                glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, tempPoint)
                
                
                let lineWidth = faceInfo.bounds.size.width / CGFloat(self.frame.width * scale)
                let sizeScaleUniform = glGetUniformLocation(self.faceProgram, "sizeScale")
                glUniform1f(GLint(sizeScaleUniform), GLfloat(lineWidth * 20))
                
                //            var scaleMatrix = GLKMatrix4Identity//GLKMatrix4Scale(GLKMatrix4Identity, 1/Float(lineWidth), 1/Float(lineWidth), 0)
                //            let scaleMatrixUniform = shader.uniformIndex("scaleMatrix")!
                //            glUniformMatrix4fv(GLint(scaleMatrixUniform), 1, GLboolean(GL_FALSE), &scaleMatrix.m.0)
                
                glDrawElements(GLenum(GL_POINTS), GLsizei(indices.count), GLenum(GL_UNSIGNED_BYTE), indices)
            }
        }
        
       

        
        
        //MARK: - 3.绘制纹理完毕，开始瘦脸
        renderThinFace()
    }
    
    //MARK: - 绘制瘦脸
    ///绘制瘦脸
    func renderThinFace() {
        //使用着色器
        glUseProgram(thinFaceProgram)
        //绑定frameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), thinFaceFrameBuffer)
        
        let faceInfo = FaceDetector.shareInstance().oneFace
        if faceInfo.landmarks.count == 0 {
            glUniform1i(hasFaceUniform, 0)
            //3.绘制纹理完毕，开始渲染到屏幕上
            displayRenderToScreen(facePointTexture)
            return
        }
        glClearColor(0.0, 0.0, 0.0, 1.0)
        //清除屏幕
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        //1.设置视口大小
        let scale = self.contentScaleFactor
        glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
        
        hasFaceUniform = glGetUniformLocation(self.thinFaceProgram, "hasFace")
        aspectRatioUniform = glGetUniformLocation(self.thinFaceProgram, "aspectRatio")
        facePointsUniform = glGetUniformLocation(self.thinFaceProgram, "facePoints")
        thinFaceDeltaUniform = glGetUniformLocation(self.thinFaceProgram, "thinFaceDelta")
        bigEyeDeltaUniform = glGetUniformLocation(self.thinFaceProgram, "bigEyeDelta")
        
        glUniform1i(hasFaceUniform, 1)
        let aspect: Float = Float(inputTextureW / inputTextureH)
        glUniform1f(aspectRatioUniform, aspect)
        
        glUniform1f(thinFaceDeltaUniform, thinFaceDelta)
        glUniform1f(bigEyeDeltaUniform, bigEyeDelta)
        
        let size = 106 * 2
        var tempPoint: [GLfloat] = [GLfloat].init(repeating: 0, count: size)
        var index = 0
        for i in 0..<faceInfo.landmarks.count {
            let point = faceInfo.landmarks[i].cgPointValue
            tempPoint[i*2+0] = GLfloat(point.x)
            tempPoint[i*2+1] = GLfloat(point.y)
            
            index += 2
            if (index == size) {
                break
            }
        }
        glUniform1fv(facePointsUniform, GLsizei(size), tempPoint)

        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
        let position = glGetAttribLocation(thinFaceProgram, "position")
        glEnableVertexAttribArray(GLuint(position))
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVertex)


        //----处理纹理数据-------
        let textCoord = glGetAttribLocation(thinFaceProgram, "inputTextureCoordinate")
        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(textCoord))
        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVerticalInvertFragment)
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), facePointTexture)
        glUniform1i(glGetUniformLocation(self.thinFaceProgram, "inputImageTexture"), 1) //单个纹理可以不用设置
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)

        
        //MARK: - 3.绘制纹理完毕，开始渲染到屏幕上
        displayRenderToScreen(thinFaceTexture)
    }
    
    
    
    ///绘制面部特征点
//    func renderFacePoint2() {
//        //MARK: - 1.绘制摄像头
//        //使用着色器
//        glUseProgram(renderProgram)
//        //绑定frameBuffer
//        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
//        
//        //设置清屏颜色
//        glClearColor(0.0, 0.0, 0.0, 1.0)
//        //清除屏幕
//        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
//        
//        //1.设置视口大小
//        let scale = self.contentScaleFactor
//        glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
//        
//       
//
//#warning("注意⚠️：想要获取shader里面的变量，这里要记住要在glLinkProgram后面、后面、后面")
//        //----处理顶点数据-------
//        //将顶点数据通过renderProgram中的传递到顶点着色程序的position
//        /*1.glGetAttribLocation,用来获取vertex attribute的入口的.
//          2.告诉OpenGL ES,通过glEnableVertexAttribArray，
//          3.最后数据是通过glVertexAttribPointer传递过去的。
//         */
//        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
//        let position = glGetAttribLocation(renderProgram, "position")
//
//        //设置合适的格式从buffer里面读取数据
//        glEnableVertexAttribArray(GLuint(position))
//
//        //设置读取方式
//        //参数1：index,顶点数据的索引
//        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
//        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
//        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
//        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
//        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
////        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))
//        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVertex)
//
//
//        //----处理纹理数据-------
//        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
//        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
//        let textCoord = glGetAttribLocation(renderProgram, "textCoordinate")
//
//        //设置合适的格式从buffer里面读取数据
//        glEnableVertexAttribArray(GLuint(textCoord))
//
//        //3.设置读取方式
//        //参数1：index,顶点数据的索引
//        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
//        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
//        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
//        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
//        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
////        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
//        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVerticalInvertFragment)
//
//        glUniform1i(glGetUniformLocation(self.renderProgram, "colorMap"), 0) //单个纹理可以不用设置
//
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
//        
//        
//        //MARK: - 2.绘制面部特征点
//        //注意⚠️：不能清屏。否则看不到照相机画面
////        glClearColor(0.0, 0.0, 0.0, 1.0)
//        //清除屏幕
////        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
//
//        //1.设置视口大小
//        glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
//
//        //使用着色器
//        glUseProgram(faceProgram)
//
//        for faceInfo in FaceDetector.shareInstance().faceModels {
//
//            var tempPoint: [GLfloat] = [GLfloat].init(repeating: 0, count: faceInfo.landmarks.count * 3)
//            var indices: [GLubyte] = [GLubyte].init(repeating: 0, count: faceInfo.landmarks.count)
//            for i in 0..<faceInfo.landmarks.count {
//                let point = faceInfo.landmarks[i].cgPointValue
//                tempPoint[i*3+0] = GLfloat(point.x * 2 - 1)
//                tempPoint[i*3+1] = GLfloat(point.y * 2 - 1)
//                tempPoint[i*3+2] = 0.0
//                indices[i] = GLubyte(i)
//
//            }
//
//            let position = glGetAttribLocation(faceProgram, "position")
//            glEnableVertexAttribArray(GLuint(position))
//            //这种方式得先把顶点数据提交到GPU
////            glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 3), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))
//            glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, tempPoint)
//
//
//            let lineWidth = faceInfo.bounds.size.width / CGFloat(self.frame.width * scale)
//            let sizeScaleUniform = glGetUniformLocation(self.faceProgram, "sizeScale")
//            glUniform1f(GLint(sizeScaleUniform), GLfloat(lineWidth * 20))
//
////            var scaleMatrix = GLKMatrix4Identity//GLKMatrix4Scale(GLKMatrix4Identity, 1/Float(lineWidth), 1/Float(lineWidth), 0)
////            let scaleMatrixUniform = shader.uniformIndex("scaleMatrix")!
////            glUniformMatrix4fv(GLint(scaleMatrixUniform), 1, GLboolean(GL_FALSE), &scaleMatrix.m.0)
//
//            glDrawElements(GLenum(GL_POINTS), GLsizei(indices.count), GLenum(GL_UNSIGNED_BYTE), indices)
//        }
//
//        //MARK: - 3.绘制瘦脸
//        //使用着色器
//        glUseProgram(thinFaceProgram)
//
//        let faceInfo = FaceDetector.shareInstance().oneFace
//        if faceInfo.landmarks.count != 0 {
//            glClearColor(0.0, 0.0, 0.0, 1.0)
//            //清除屏幕
//            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
//            
//            //1.设置视口大小
//            glViewport(0, 0, GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
//            
//            hasFaceUniform = glGetUniformLocation(self.thinFaceProgram, "hasFace")
//            aspectRatioUniform = glGetUniformLocation(self.thinFaceProgram, "aspectRatio")
//            facePointsUniform = glGetUniformLocation(self.thinFaceProgram, "facePoints")
//            thinFaceDeltaUniform = glGetUniformLocation(self.thinFaceProgram, "thinFaceDelta")
//            bigEyeDeltaUniform = glGetUniformLocation(self.thinFaceProgram, "bigEyeDelta")
//            
//            glUniform1i(hasFaceUniform, 1)
//            let aspect: Float = Float(inputTextureW / inputTextureH)
//            glUniform1f(aspectRatioUniform, aspect)
//            
//            glUniform1f(thinFaceDeltaUniform, thinFaceDelta)
//            glUniform1f(bigEyeDeltaUniform, bigEyeDelta)
//            
//            let size = 106 * 2
//            var tempPoint: [GLfloat] = [GLfloat].init(repeating: 0, count: size)
//            var index = 0
//            for i in 0..<faceInfo.landmarks.count {
//                let point = faceInfo.landmarks[i].cgPointValue
//                tempPoint[i*2+0] = GLfloat(point.x)
//                tempPoint[i*2+1] = GLfloat(point.y)
//                
//                index += 2
//                if (index == size) {
//                    break
//                }
//            }
//            glUniform1fv(facePointsUniform, GLsizei(size), tempPoint)
//            
//            //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
//            let thinFacePosition = glGetAttribLocation(thinFaceProgram, "position")
//            glEnableVertexAttribArray(GLuint(thinFacePosition))
//            glVertexAttribPointer(GLuint(thinFacePosition), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardVertex)
//            
//            
//            //----处理纹理数据-------
//            let thinFaceTextCoord = glGetAttribLocation(thinFaceProgram, "inputTextureCoordinate")
//            //设置合适的格式从buffer里面读取数据
//            glEnableVertexAttribArray(GLuint(thinFaceTextCoord))
//            glVertexAttribPointer(GLuint(thinFaceTextCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, standardFragment)
//            
//            glUniform1i(glGetUniformLocation(self.thinFaceProgram, "inputImageTexture"), 0) //单个纹理可以不用设置
//            
//            glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
//        }
//        
//        if (EAGLContext.current() == myContext) {
//            myContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
//        }
//    }
}



