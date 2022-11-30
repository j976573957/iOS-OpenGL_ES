//
//  DDView.swift
//  OpenGL ES-02
//
//  Created by Mac on 2022/8/8.
//

import UIKit
import GLKit
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
    
    //在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
    var myEagLayer: CAEAGLLayer!
    var myContext: EAGLContext!
    var renderBuffer: GLuint = 0
    var frameBuffer: GLuint = 0
    var myProgram: GLuint = 0
    
    var indices: [GLuint] = []
    var xDegree: Float = 0
    var yDegree: Float = 0
    var zDegree: Float = 0
    var bX: Bool = false
    var bY: Bool = false
    var bZ: Bool = false
    var speed: Float = 5.0
  
    var myTimer: Timer?
    @IBOutlet weak var lbSpeed: UILabel!
    
    //MARK: - 事件
    @IBAction func xClicked(_ sender: UIButton) {
        if myTimer == nil {
            myTimer = Timer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
            RunLoop.current.add(myTimer!, forMode: .common)
        }
        bX = !bX
    }
    
    @IBAction func yClicked(_ sender: UIButton) {
        if myTimer == nil {
            myTimer = Timer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
            RunLoop.current.add(myTimer!, forMode: .common)
        }
        bY = !bY
    }
    
    @IBAction func zClicked(_ sender: UIButton) {
        if myTimer == nil {
            myTimer = Timer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
            RunLoop.current.add(myTimer!, forMode: .common)
        }
        bZ = !bZ
    }
    
    @objc func reDegree() {
        //如果停止X轴旋转，X = 0则度数就停留在暂停前的度数.
        //更新度数
        xDegree += (bX ? 1 : 0) * speed
        yDegree += (bY ? 1 : 0) * speed
        zDegree += (bZ ? 1 : 0) * speed
        //重新渲染
        renderLayer()
    }

    @IBAction func resetDidClicked(_ sender: UIButton) {
        if myTimer != nil {
            myTimer?.invalidate()
            myTimer = nil
        }
        bX = false
        bY = false
        bZ = false
        xDegree = 0
        yDegree = 0
        zDegree = 0
        speed = 5.0
        lbSpeed.text = "speed: \(Int(speed))"
        renderLayer()
    }
    
    @IBAction func speedLow(_ sender: Any) {
        speed -= 1
        lbSpeed.text = "speed: \(Int(speed))"
    }
    
    @IBAction func speedAdd(_ sender: Any) {
        speed += 1
        lbSpeed.text = "speed: \(Int(speed))"
    }
    
    
    //MARK: - OpenGL ES
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //1.设置图层
        setupLayer()
        
        //2.设置上下文
        setupContext()
        
        //3.设置RenderBuffer
        setupRenderBuffer()
        
        //4.设置FrameBuffer
        setupFrameBuffer()
        
        //5.编译、链接着色器（shader）
        compileAndLinkShader()
        
        //6.设置VBO (Vertex Buffer Objects)
        setupVBO()
        
        //7.设置纹理
        setupTexture("cTest")
        
        //8.渲染
        renderLayer()
        
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
    
    //5.1 编译着色器（shader）
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
    
    //5.2 链接着色器（shader）
    func compileAndLinkShader() {
        //1. 创建program
        let program: GLuint = glCreateProgram()
        
        //2. 编译顶点着色器程序、片元着色器程序
        let vertShader = compileShader(shaderName: "shaderv.glsl", shaderType: GLenum(GL_VERTEX_SHADER))
        let fragShader = compileShader(shaderName: "shaderf.glsl", shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        //3. 把着色器绑定到最终的程序
        glAttachShader(program, vertShader)
        glAttachShader(program, fragShader)
        
        //释放不需要的shader
        glDeleteShader(vertShader)
        glDeleteShader(fragShader)
        
        myProgram = program
        
        //4.链接
        glLinkProgram(myProgram)
        var linkStatus: GLint = 0
        //获取链接状态
        glGetProgramiv(myProgram, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            NSLog("link error")
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(myProgram, GLsizei(MemoryLayout<GLchar>.size * 512), nil, message)
            let str = String(utf8String: message)
            print("error = \(str ?? "没获取到错误信息")")
            return
        }
        
        NSLog("Program link success!")
    }
    
    //6.设置VBO (Vertex Buffer Objects)
    func setupVBO() {
        //6.设置顶点、纹理坐标
        //顶点数组
        //前3个元素，是顶点数据；中间3个元素，是顶点颜色值，最后2个是纹理坐标
        let attrArr: [GLfloat] = [
           -0.5,  0.5, 0.0,     0.0, 0.0, 0.5,       0.0, 1.0,//左上
            0.5,  0.5, 0.0,     0.0, 0.5, 0.0,       1.0, 1.0,//右上
           -0.5, -0.5, 0.0,     0.5, 0.0, 1.0,       0.0, 0.0,//左下
            0.5, -0.5, 0.0,     0.0, 0.0, 0.5,       1.0, 0.0,//右下
            0.0,  0.0, 1.0,     1.0, 1.0, 1.0,       0.5, 0.5,//顶点
        ]
        
        //创建绘制索引数组
        let indices: [GLuint] = [
            0, 3, 2,
            0, 1, 3,
            0, 2, 4,
            0, 4, 1,
            2, 3, 4,
            1, 4, 3,
        ]
         
        
        //金字塔-线
//        let indices: [GLuint] = [
//            0, 4,
//            1, 4,
//            2, 4,
//            3, 4,
//
//            0, 1,
//            0, 2,
//            3, 2,
//            3, 1,
//
//            0, 3
//        ]
        self.indices = indices
        
        //-----处理顶点数据--------
        //顶点缓存区
        var attrBuffer: GLuint = 0
        //申请一个缓存区标识符
        glGenBuffers(1, &attrBuffer)
        //将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), attrBuffer)
        //把顶点数据从CPU拷贝到GPU上
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * attrArr.count, attrArr, GLenum(GL_DYNAMIC_DRAW))
    }
    
    //7.设置纹理
    @discardableResult func setupTexture(_ name: String) -> GLuint {
        //1.获取图片的CGImageRef
        guard let spriteImage: CGImage = UIImage(named: name)?.cgImage else {
            NSLog("读取图片失败")
            return 0
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
//        spriteContext.translateBy(x: 0, y: CGFloat(height))//向下平移图片的高度
//        spriteContext.scaleBy(x: 1, y: -1)
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
        
        //7.绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
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
        
        //绑定纹理
        /*
         参数1：纹理维度
         参数2：纹理ID,因为只有一个纹理，给0就可以了。
         */
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        //释放spriteData
        free(spriteData)
        
        return 0
    }
    
    //8.开始绘制
    func renderLayer() {
        //设置清屏颜色
        glClearColor(0.0, 0.0, 1.0, 1.0)
        //清除屏幕
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        //1.设置视口大小
        let scale = UIScreen.main.scale
        glViewport(GLint(self.frame.origin.x * scale), GLint(self.frame.origin.y * scale), GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))

        //使用着色器
        glUseProgram(myProgram)

#warning("注意⚠️：想要获取shader里面的变量，这里要记住要在glLinkProgram后面、后面、后面")
        /*
         一个一致变量在一个图元的绘制过程中是不会改变的，所以其值不能在glBegin/glEnd中设置。一致变量适合描述在一个图元中、一帧中甚至一个场景中都不变的值。一致变量在顶点shader和片段shader中都是只读的。首先你需要获得变量在内存中的位置，这个信息只有在连接程序之后才可获得。
         */
        
        //--------处理顶点数据-------
        //1.将顶点数据通过myProgram中的传递到顶点着色程序的position
        let position = glGetAttribLocation(myProgram, "position")
        //2.
        glEnableVertexAttribArray(GLuint(position))
        
        //3.设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(position), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), nil)
        
        //--------处理顶点颜色值-------
        //1.将顶点数据通过myProgram中的传递到顶点着色程序的positionColor
        let positionColor = glGetAttribLocation(myProgram, "positionColor")
        glEnableVertexAttribArray(GLuint(positionColor))
        glVertexAttribPointer(GLuint(positionColor), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))
        
        
        //----处理纹理数据-------
        //1.glGetAttribLocation,用来获取vertex attribute的入口的.
        //注意：第二参数字符串必须和shaderv.vsh中的输入变量：textCoordinate保持一致
        let textCoord = glGetAttribLocation(myProgram, "textCoordinate")
        
        //设置合适的格式从buffer里面读取数据
        glEnableVertexAttribArray(GLuint(textCoord))
        
        //3.设置读取方式
        //参数1：index,顶点数据的索引
        //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
        //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
        //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
        //参数5：stride,连续顶点属性之间的偏移量，默认为0；
        //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
        glVertexAttribPointer(GLuint(textCoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 6))
        
        
        //----处理矩阵数据-------
        //找到myProgram中的projectionMatrix、modelViewMatrix 2个矩阵的地址。如果找到则返回地址，否则返回-1，表示没有找到2个对象。
        let projectionMatrixSlot = glGetUniformLocation(myProgram, "projectionMatrix")
        let modelViewMatrixSlot = glGetUniformLocation(myProgram, "modelViewMatrix")
        
        let width = self.frame.size.width
        let height = self.frame.size.height
        
        //创建4 * 4矩阵 获取单元矩阵
        var _projectionMatrix: GLKMatrix4 = GLKMatrix4Identity
        
        //计算纵横比例 = 长/宽
        let aspect = width / height; //长宽比
        
        //获取透视矩阵
        /*
         参数1：矩阵
         参数2：视角，度数为单位
         参数3：纵横比
         参数4：近平面距离
         参数5：远平面距离
         参考PPT
         */
        //源码实现：在这里面
        //        ksPerspective(<#T##result: UnsafeMutablePointer<KSMatrix4>!##UnsafeMutablePointer<KSMatrix4>!#>, <#T##fovy: Float##Float#>, <#T##aspect: Float##Float#>, <#T##nearZ: Float##Float#>, <#T##farZ: Float##Float#>)
        let perspectiveMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30), Float(aspect), 5, 20)
        _projectionMatrix = GLKMatrix4Multiply(_projectionMatrix, perspectiveMatrix)
        
        //设置glsl里面的投影矩阵
        /*
         void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
         参数列表：
         location:指要更改的uniform变量的位置
         count:更改矩阵的个数
         transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
         value:执行count个元素的指针，用来更新指定uniform变量
         */
//        let count = MemoryLayout.size(ofValue: _projectionMatrix.m) / MemoryLayout.size(ofValue: _projectionMatrix.m.0)
//        withUnsafePointer(to: &_projectionMatrix.m) { (pointer) in
//            pointer.withMemoryRebound(to: GLfloat.self, capacity: count, { (pon) in
//                glUniformMatrix4fv(projectionMatrixSlot, 1, GLboolean(GL_FALSE), pon)
//            })
//        }
        glUniformMatrix4fv(projectionMatrixSlot, 1, GLboolean(GL_FALSE), &_projectionMatrix.m.0)
        
        //开启剔除操作效果 （三角形逆时针方向为正面）
        glEnable(GLenum(GL_CULL_FACE))
        
        //创建一个4 * 4 矩阵，模型视图
        var _modelViewMatrix: GLKMatrix4 = GLKMatrix4Identity
        //平移，z轴平移-10
        _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0.0, 0.0, -10.0)
        
        //创建一个4 * 4 矩阵，旋转矩阵
        var _rotationMatrix: GLKMatrix4 = GLKMatrix4Identity
        //旋转
        _rotationMatrix = GLKMatrix4Rotate(_rotationMatrix, GLKMathDegreesToRadians(xDegree), 1.0, 0.0, 0.0)
        _rotationMatrix = GLKMatrix4Rotate(_rotationMatrix, GLKMathDegreesToRadians(yDegree), 0.0, 1.0, 0.0)
        _rotationMatrix = GLKMatrix4Rotate(_rotationMatrix, GLKMathDegreesToRadians(zDegree), 0.0, 0.0, 1.0)
        
        //注意⚠️⚠️⚠️：把变换矩阵相乘，注意先后顺序 ，将平移矩阵与旋转矩阵相乘，结合到模型视图
        _modelViewMatrix = GLKMatrix4Multiply(_modelViewMatrix, _rotationMatrix)
        
        // 加载模型视图矩阵 modelViewMatrixSlot
        //设置glsl里面的投影矩阵
        /*
         void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
         参数列表：
         location:指要更改的uniform变量的位置
         count:更改矩阵的个数
         transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
         value:执行count个元素的指针，用来更新指定uniform变量
         */
//        let count1 = MemoryLayout.size(ofValue: _modelViewMatrix.m) / MemoryLayout.size(ofValue: _modelViewMatrix.m.0)
//        withUnsafePointer(to: &_modelViewMatrix.m) { (pointer) in
//            pointer.withMemoryRebound(to: GLfloat.self, capacity: count1, { (pon) in
//                glUniformMatrix4fv(modelViewMatrixSlot, 1, GLboolean(GL_FALSE), pon)
//            })
//        }
        glUniformMatrix4fv(modelViewMatrixSlot, 1, GLboolean(GL_FALSE), &_modelViewMatrix.m.0)
        
        //使用索引绘图
        /*
         void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
         参数列表：
         mode:要呈现的画图的模型
                    GL_POINTS
                    GL_LINES
                    GL_LINE_LOOP
                    GL_LINE_STRIP
                    GL_TRIANGLES
                    GL_TRIANGLE_STRIP
                    GL_TRIANGLE_FAN
         count:绘图个数
         type:类型
                 GL_BYTE
                 GL_UNSIGNED_BYTE
                 GL_SHORT
                 GL_UNSIGNED_SHORT
                 GL_INT
                 GL_UNSIGNED_INT
         indices：绘制索引数组

         注意：⚠️⚠️⚠️
         glArrayElements()、glDrawElements()和glDrawRangeElements()能够对数据数组进行随机存取，
         但是glDrawArrays()只能按顺序访问它们。因为前者支持顶点索引的机制
         */
        let dotCount = MemoryLayout<GLfloat>.size * indices.count / MemoryLayout<GLfloat>.size
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(dotCount), GLenum(GL_UNSIGNED_INT), indices)
        
        myContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
    }
}
