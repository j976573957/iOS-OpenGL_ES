//
//  DDView.swift
//  OpenGL ES-02
//
//  Created by Mac on 2022/8/18.
//

import UIKit
import OpenGLES.ES2

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

class DDView: UIView {
    
    private var eaglLayer: CAEAGLLayer! //图层
    private var mContext: EAGLContext?//上下文
    
    private var renderbuffer: GLuint = 0

    private var imgTexture: GLuint = 0//纹理
    private var tempTexture: GLuint = 0
    
    private var tempFrameBuffer: GLuint = 0
    private var frameBuffer: GLuint = 0
    
    private var saturationProgram: GLuint = 0
    private var temperatureProgram: GLuint = 0
    
    var outImage: UIImage?
    
    //色温
    var temperature: CGFloat = 0 {
        didSet {
            //重新渲染
            self.render()
        }
    }
    //饱和度
    var saturation: CGFloat = 0 {
        didSet {
            //重新渲染
            self.render()
        }
    }

    //MARK: - Public
    //将图片加入到GLView上
    func layoutGLViewWithImage(_ image: UIImage) {
        //1.设置色温和饱和度
        self.setupData()
        //2.设置图层
        self.setupLayer()
        //3.设置图形上下文
        self.setupContext()
        //4.设置renderBuffer
        self.setupRenderBuffer()
        //5.设置frameBuffer
        self.setupFrameBuffer()
        //6.检查FrameBuffer
//        var error: NSError?
//        assert(self.checkFramebuffer(error: &error), error?.userInfo["ErrorMessage"] as! String)
        //7.链接shader 色温
        self.compileTemperatureShaders()
        
        //8.链接shader 饱和度
        self.compileSaturationShaders()
        
        //9.设置VBO (Vertex Buffer Objects)
        self.setupVBO()
        
        //10.设置纹理
        self.setupTemp()
        
        //10.设置纹理图片
        self.setupTextureWithImage(image)
        
        //11.渲染
        self.render()
    }
    
    
    //MARK: - Override
    // 想要显示 OpenGL 的内容, 需要把它缺省的 layer 设置为一个特殊的 layer(CAEAGLLayer).
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    //设置色温\饱和度初始值
    func setupData() {
        temperature = 0.5
        saturation = 0.5
    }
    
    //设置图层
    func setupLayer() {
        // 用于显示的layer
        eaglLayer = self.layer as? CAEAGLLayer
        /*
         1.kEAGLDrawablePropertyRetainedBacking
         表示绘图表面显示后，是否保留其内容，通过一个NSNumber 包装一个bool值。如果是NO,表示
         显示内容后，不能依赖于相同的内容；如果是YES，表示显示内容后不变，一般只有在需要内容保存不变的情况下才使用YES，设置为YES,会导致性能降低，内存使用量降低。一般设置为NO。
         
         2.kEAGLDrawablePropertyColorFormat
         表示绘制表面的内部颜色缓存区格式
         */
        eaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : false, kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8]
        //  CALayer默认是透明的，而透明的层对性能负荷很大。所以将其关闭。
        eaglLayer.isOpaque = true
    }
    
    //设置图形上下文
    func setupContext() {
        if (mContext == nil) {
            // 创建GL环境上下文
            // EAGLContext 管理所有通过 OpenGL 进行 Draw 的信息.
            mContext = EAGLContext(api: .openGLES2)
        }
        assert((mContext != nil) && EAGLContext.setCurrent(mContext), "初始化GL环境失败")
    }
    
    //设置RenderBuffer
    func setupRenderBuffer() {
        //1.定义一个缓存区
        var buffer: GLuint = 0
        //2.申请一个缓存区标识符
        glGenRenderbuffers(1, &buffer)
        //3.将标识符绑定到GL_RENDERBUFFER
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), buffer)
        
        renderbuffer = buffer
        
        //frame buffer仅仅是管理者，不需要分配空间；render buffer的存储空间的分配，对于不同的render buffer，使用不同的API进行分配，而只有分配空间的时候，render buffer句柄才确定其类型
        
        //renderBuffer渲染缓存区分配存储空间
        mContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: eaglLayer)
    }
    
    //设置FrameBuffer
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
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), renderbuffer)
    }
    
    //编译着色器
    func compileShader(shaderName: String, shaderType: GLenum) -> GLuint {
        
        //路径
        let shaderPath = Bundle.main.path(forResource: shaderName, ofType: nil)!
        //创建临时shader
        let shader: GLuint = glCreateShader(shaderType)
        //获取shader路径-C语言字符串
        if let context = try? String(contentsOfFile: shaderPath, encoding: .utf8) {
#warning("法一")
            if let value = context.cString(using:String.Encoding.utf8) {
                var tempString: UnsafePointer<GLchar>? = UnsafePointer<GLchar>?(value)
                glShaderSource(shader, 1, &tempString, nil)
            }
#warning("法二")
//            context.withCString { (pointer) in
//                var source: UnsafePointer<GLchar>? = pointer
//                //绑定shader
//                //将顶点着色器源码附加到着色器对象上。
//                //参数1：shader,要编译的着色器对象 *shader
//                //参数2：numOfStrings,传递的源码字符串数量 1个
//                //参数3：strings,着色器程序的源码（真正的着色器程序源码）
//                //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
//                glShaderSource(shader, 1, &source, nil)
//            }
        } else {
            NSLog("Failed to load vertex shader")
            return 0
        }
        
        //编译Shader
        glCompileShader(shader)
        
        //获取加载Shader的日志信息
        //日志信息长度
        var logLength: GLint = 0
        /*
        在OpenGL中有方法能够获取到 shader错误
        参数1:对象,从哪个Shader
        参数2:获取信息类别,
                GL_COMPILE_STATUS       //编译状态
                GL_INFO_LOG_LENGTH      //日志长度
                GL_SHADER_SOURCE_LENGTH //着色器源文件长度
                GL_SHADER_COMPILER  //着色器编译器
         参数3:获取长度
         */
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &logLength)
        
        //判断日志长度 > 0
        if (logLength == GL_FALSE)
        {
            //创建日志字符串
            //malloc(Int(logLength))
            //UnsafeMutablePointer<GLchar>.init(bitPattern: Int(logLength))!
            let log: UnsafeMutablePointer<GLchar> = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            /*
             获取日志信息
             参数1:着色器
             参数2:日志信息长度
             参数3:日志信息长度地址
             参数4:日志存储的位置
             */
            //            glGetShaderInfoLog(shader, logLength, &logLength, log)
            glGetShaderInfoLog(shader, 512, nil, log)
            
            //打印日志信息
            NSLog("Shader compile log:\n%s", log)
            
            //释放日志字符串
            free(log)
            
        }
        
        return shader
        
    }
    
    //饱和度
    private func compileSaturationShaders() {
        //1. 创建program
        let program: GLuint = glCreateProgram()
        
        //2. 编译顶点着色器程序、片元着色器程序
        let vertShader = compileShader(shaderName: "shaderv.vsh", shaderType: GLenum(GL_VERTEX_SHADER))
        let fragShader = compileShader(shaderName: "Saturation.fsh", shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        //3. 把着色器绑定到最终的程序
        glAttachShader(program, vertShader)
        glAttachShader(program, fragShader)
        
        //释放不需要的shader
        glDeleteShader(vertShader)
        glDeleteShader(fragShader)
        
        saturationProgram = program
        
        //4.链接
        glLinkProgram(saturationProgram)
        var linkStatus: GLint = 0
        //获取链接状态
        glGetProgramiv(saturationProgram, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            NSLog("link error")
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(saturationProgram, GLsizei(MemoryLayout<GLchar>.size * 512), nil, message)
            let str = String(utf8String: message)
            print("error = \(str ?? "没获取到错误信息")")
            return
        }
        
        NSLog("saturationProgram link success!")
    }
    
    //色温处理shaders编译
    private func compileTemperatureShaders() {
        //1. 创建program
        let program: GLuint = glCreateProgram()
        
        //2. 编译顶点着色器程序、片元着色器程序
        let vertShader = compileShader(shaderName: "shaderv.vsh", shaderType: GLenum(GL_VERTEX_SHADER))
        let fragShader = compileShader(shaderName: "Temperature.fsh", shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        //3. 把着色器绑定到最终的程序
        glAttachShader(program, vertShader)
        glAttachShader(program, fragShader)
        
        //释放不需要的shader
        glDeleteShader(vertShader)
        glDeleteShader(fragShader)
        
        temperatureProgram = program
        
        //4.链接
        glLinkProgram(temperatureProgram)
        var linkStatus: GLint = 0
        //获取链接状态
        glGetProgramiv(temperatureProgram, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            NSLog("link error")
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(temperatureProgram, GLsizei(MemoryLayout<GLchar>.size * 512), nil, message)
            let str = String(utf8String: message)
            print("error = \(str ?? "没获取到错误信息")")
            return
        }
        
        NSLog("temperatureProgram link success!")
    }
    

    
    ///9.设置VBO (Vertex Buffer Objects)
    private func setupVBO() {
        //6.设置顶点、纹理坐标
        //前3个是顶点坐标，后2个是纹理坐标
        let attrArr: [GLfloat] = [
            1.0, -1.0, 0.0,    1.0, 0.0, //右下
            -1.0, 1.0, 0.0,    0.0, 1.0, // 左上
            -1.0, -1.0, 0.0,   0.0, 0.0, // 左下
            
            1.0, 1.0, 0.0,     1.0, 1.0, // 右上
            -1.0, 1.0, 0.0,    0.0, 1.0, // 左上
            1.0, -1.0, 0.0,    1.0, 0.0  // 右下
        ]
        /*
        let attrArr: [GLfloat] = [
            //解决图片倒置问题 法二：☑️
            1.0, -1.0, 0.0,        1.0, 1.0, //右下
            -1.0, 1.0, 0.0,        0.0, 0.0, // 左上
            -1.0, -1.0, 0.0,       0.0, 1.0, // 左下
            
            1.0, 1.0, 0.0,         1.0, 0.0, // 右上
            -1.0, 1.0, 0.0,        0.0, 0.0, // 左上
            1.0, -1.0, 0.0,        1.0, 1.0, // 右下
        ]
         */
        
        //-----处理顶点数据--------
        //顶点缓存区
        var attrBuffer: GLuint = 0
        //申请一个缓存区标识符
        glGenBuffers(1, &attrBuffer)
        //将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), attrBuffer)
        //把顶点数据从CPU拷贝到GPU上
        /*
         数据拷贝到缓存对象
         void glBufferData(GLenum target，GLsizeiptr size, const GLvoid*  data, GLenum usage);
         target:可以为GL_ARRAY_BUFFER或GL_ELEMENT_ARRAY
         size:待传递数据字节数量
         data:源数据数组指针
         usage:
         GL_STATIC_DRAW
         GL_STATIC_READ
         GL_STATIC_COPY
         GL_DYNAMIC_DRAW
         GL_DYNAMIC_READ
         GL_DYNAMIC_COPY
         GL_STREAM_DRAW
         GL_STREAM_READ
         GL_STREAM_COPY
         
         ”static“表示VBO中的数据将不会被改动（一次指定多次使用），
         ”dynamic“表示数据将会被频繁改动（反复指定与使用），
         ”stream“表示每帧数据都要改变（一次指定一次使用）。
         ”draw“表示数据将被发送到GPU以待绘制（应用程序到GL），
         ”read“表示数据将被客户端程序读取（GL到应用程序），”
         */
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * attrArr.count, attrArr, GLenum(GL_STATIC_DRAW))
    }

    //设置纹理从图片
    func setupTextureWithImage(_ image: UIImage) {
        
        //1.获取图片的CGImageRef
        guard let spriteImage: CGImage = image.cgImage else {
            NSLog("读取图片失败")
            return
        }
        
        //2.读取图片的大小：宽和高
        let width = spriteImage.width
        let height = spriteImage.height
        
        //3.获取图片字节数： 宽x高x4(RGBA)
//        let spriteData: UnsafeMutablePointer = UnsafeMutablePointer<GLbyte>.allocate(capacity: MemoryLayout<GLbyte>.size * width * height * 4)
        let spriteData: UnsafeMutableRawPointer = calloc(width * height * 4, MemoryLayout<GLbyte>.size)
        
        //4.创建上下文
        /*
         参数1：data,指向要渲染的绘制图像的内存地址
         参数2：width,bitmap的宽度，单位为像素
         参数3：height,bitmap的高度，单位为像素
         参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
         参数5：bytesPerRow,bitmap的每一行的内存所占的比特数
         参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
         */
        let spriteContext: CGContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        //5.在CGContextRef上绘图
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        /*
         CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
         CGContextDrawImage
         参数1：绘图上下文
         参数2：rect坐标
         参数3：绘制的图片
         */

        //解决图片倒置问题 方法三: ☑️
        spriteContext.translateBy(x: 0, y: CGFloat(height))//向下平移图片的高度
        spriteContext.scaleBy(x: 1, y: -1)
        spriteContext.draw(spriteImage, in: rect)
        /*
         解决图片倒置问题 方法三:
         CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
         CGContextTranslateCTM(spriteContext, 0, rect.size.height);
         CGContextScaleCTM(spriteContext, 1.0, -1.0);
         CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
         CGContextDrawImage(spriteContext, rect, spriteImage);
         */
        
        
        //6、画图完毕就释放上下文->swift 自动管理，OC手动释放：CGContextRelease(spriteContext);
//        CGContextRelease(spriteContext);
        
        //在绑定纹理之前,激活纹理单元 glActiveTexture
        glActiveTexture(GLenum(GL_TEXTURE1))
        
        //生成纹理标记
        glGenTextures(1, &imgTexture)
        
        //绑定纹理
        glBindTexture(GLenum(GL_TEXTURE_2D), imgTexture)
        
        //设置纹理属性
        /*
         参数1：纹理维度
         参数2：线性过滤、为s,t坐标设置模式
         参数3：wrapMode,环绕模式
         */
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        
        //载入纹理2D数据
        /*
         参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
         参数2：加载的层次，一般设置为0
         参数3：纹理的颜色值GL_RGBA
         参数4：宽
         参数5：高
         参数6：border，边界宽度
         参数7：format
         参数8：type
         参数9：纹理数据
         */
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
        
        //释放spriteData
        free(spriteData)
        
    }
    ///10.设置纹理
    private func setupTemp() {
        //绑定纹理之前,激活纹理
        glActiveTexture(GLenum(GL_TEXTURE0))
        //申请纹理标记
        glGenTextures(1, &tempTexture)
        //绑定纹理
        glBindTexture(GLenum(GL_TEXTURE_2D), tempTexture)
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
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(self.frame.size.width * self.contentScaleFactor), GLsizei(self.frame.size.height * self.contentScaleFactor), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
        //设置纹理参数
        //放大\缩小过滤
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR )
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        
        //申请_tempFramesBuffe标记
        glGenFramebuffers(1, &tempFrameBuffer)
        //绑定FrameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), tempFrameBuffer)
        
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
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), tempTexture, 0)
    }

    private func render() {
        //绘制第一个滤镜
        //使用色温着色器
        glUseProgram(temperatureProgram)
        //绑定frameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), tempFrameBuffer)
        //设置清屏颜色
        glClearColor(0.0, 1.0, 0.0, 1.0)
        //清除屏幕
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        //1.设置视口大小
        glViewport(0, 0, GLsizei(self.frame.size.width * self.contentScaleFactor), GLsizei(self.frame.size.height * self.contentScaleFactor))

#warning("注意⚠️：想要获取shader里面的变量，这里要记住要在glLinkProgram后面、后面、后面")
        //----处理顶点数据-------
        //将顶点数据通过myPrograme中的传递到顶点着色程序的position
        /*1.glGetAttribLocation,用来获取vertex attribute的入口的.
          2.告诉OpenGL ES,通过glEnableVertexAttribArray，
          3.最后数据是通过glVertexAttribPointer传递过去的。
         */
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(temperatureProgram, "position")))
        
        //设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(glGetAttribLocation(temperatureProgram, "position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))

        
        //----处理纹理数据-------
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(temperatureProgram, "inputTextureCoordinate")))
        
        //3.设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(glGetAttribLocation(temperatureProgram, "inputTextureCoordinate")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        
        //纹理
        glUniform1i(glGetUniformLocation(temperatureProgram, "inputImageTexture"), 1)
        //色温
        glUniform1f(glGetUniformLocation(temperatureProgram, "temperature"), GLfloat(temperature))
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        
        
        
        //绘制第二个滤镜
        //使用饱和度着色器
        glUseProgram(saturationProgram)
        //绑定frameBuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        //绑定RenderBuffer
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderbuffer)
        //设置清屏颜色
        glClearColor(0.0, 1.0, 0.0, 1.0)
        //清除屏幕
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        //1.设置视口大小
        glViewport(0, 0, GLsizei(self.frame.size.width * self.contentScaleFactor), GLsizei(self.frame.size.height * self.contentScaleFactor))
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致

        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(saturationProgram, "position")))

        //设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(glGetAttribLocation(saturationProgram, "position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))


        //----处理纹理数据-------
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(saturationProgram, "inputTextureCoordinate")))

        //3.设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(glGetAttribLocation(saturationProgram, "inputTextureCoordinate")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))

        //纹理
        glUniform1i(glGetUniformLocation(saturationProgram, "inputImageTexture"), 0)
        
        //饱和度
        glUniform1f(glGetUniformLocation(saturationProgram, "saturation"), GLfloat(saturation))

        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        mContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
        outImage = getImageFromBuffer(width: Int(self.frame.size.width * self.contentScaleFactor), height: Int(self.frame.size.height * self.contentScaleFactor))
    }
    
    //从帧缓冲区获取图片
    func getImageFromBuffer(width: Int, height: Int) -> UIImage {
        let x: GLint = 0, y: GLint = 0
        let dataLength = width * height * 4
        let data: UnsafeMutableRawPointer = calloc(width * height * 4, MemoryLayout<GLbyte>.size)
        
        //数据对齐
        //指定要设置的参数的符号名称。 一个值会影响像素数据到内存的打包：GL_PACK_ALIGNMENT。 另一个影响从内存中解压缩像素数据：GL_UNPACK_ALIGNMENT。
        glPixelStorei(GLenum(GL_PACK_ALIGNMENT), 4)
        glReadPixels(x, y, GLsizei(width), GLsizei(height), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        
        let ref: CGDataProvider = CGDataProvider(dataInfo: nil, data: data, size: dataLength) { mRawPointer, rawPoint, count in
            
        }!
        let colorspace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let iref: CGImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: colorspace, bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue),
                                    provider: ref, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
        
        //法一
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        let cgcontext: CGContext = UIGraphicsGetCurrentContext()!
        cgcontext.setBlendMode(CGBlendMode.copy)
        cgcontext.draw(iref, in: CGRect(x: 0, y: 0, width: width, height: height))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
//        //法二 ：
//        let image = UIImage(cgImage: iref, scale: 1.0, orientation: .downMirrored)
        
        free(data)
        
        //swift 自动管理了
//        CFRelease(ref)
//        CFRelease(colorspace)
//        CGImageRelease(iref)
        return image
    }

    
    //MARK: - Life Cycle
    deinit {
        if (frameBuffer != 0) {
            glDeleteFramebuffers(1, &frameBuffer)
            frameBuffer = 0
        }
        if (renderbuffer != 0) {
            glDeleteRenderbuffers(1, &renderbuffer)
            renderbuffer = 0
        }
        mContext = nil
    }
}
