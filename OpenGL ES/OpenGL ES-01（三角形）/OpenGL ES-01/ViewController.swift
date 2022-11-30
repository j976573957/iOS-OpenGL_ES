//
//  ViewController.swift
//  OpenGL ES-01
//
//  Created by Mac on 2022/8/5.
//

import UIKit
import GLKit
import AVFoundation

class ViewController: GLKViewController {

    //EAGLContext 是苹果在iOS 平台下实现的OpenGLES渲染层，用于渲染结果在目标surface上的更新。
    var glkView: GLKView!
    var context: EAGLContext!
    var myEffect: GLKBaseEffect! //着色器或者光照
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //1.设置图层
        setupLayer()
        //2.设置上下文
        setupContext()
        //3.设置顶点数据（位置，颜色，纹理(渲染图片时用到)）
        setupVertexData()
        //4.设置着色器：顶点着色器和片元着色器 (苹果GLKit已经将这两个着色器封装了)
        setupEffect()
        //5.加载纹理
        setupTexture()
        //6.绘制渲染(GLKViewDelegate 实现)
    }

    
    //1.设置图层
    func setupLayer() {
        //创建一个OpenGL ES上下文并将其分配给从storyboard加载的视图
        //注意⚠️：这里需要把storyboard的View记得添加为GLKView, 还有把ViewController继承自： GLKViewController
        glkView = self.view as? GLKView
        
        //配置视图创建的渲染缓冲区
        /*
         OpenGL ES 有一个缓存区，它用以存储将在屏幕中显示的颜色。你可以使用其属性来设置缓冲区中的每个
         像素的颜色格式。
         默认：GLKViewDrawableColorFormatRGBA8888，即缓存区的每个像素的最小组成部分（RGBA）使用
         8个bit，（所以每个像素4个字节，4*8个bit）。
         GLKViewDrawableColorFormatRGB565,如果你的APP允许更小范围的颜色，即可设置这个。会让你的
         APP消耗更小的资源（内存和处理时间）
         */
        glkView.drawableColorFormat = .RGBA8888
        
        /*
         OpenGL ES 另一个缓存区，深度缓冲区。帮助我们确保可以更接近观察者的对象显示在远一些的对象前面。
         （离观察者近一些的对象会挡住在它后面的对象）
         默认：OpenGL把接近观察者的对象的所有像素存储到深度缓冲区，当开始绘制一个像素时，它（OpenGL）
         首先检查深度缓冲区，看是否已经绘制了更接近观察者的什么东西，如果是则忽略它（要绘制的像素，
         就是说，在绘制一个像素之前，看看前面有没有挡着它的东西，如果有那就不用绘制了）。否则，
         把它增加到深度缓冲区和颜色缓冲区。
         缺省值是GLKViewDrawableDepthFormatNone，意味着完全没有深度缓冲区。
         但是如果你要使用这个属性（一般用于3D游戏），你应该选择GLKViewDrawableDepthFormat16
         或GLKViewDrawableDepthFormat24。这里的差别是使用GLKViewDrawableDepthFormat16
         将消耗更少的资源，但是当对象非常接近彼此时，你可能存在渲染问题（）
         */
        glkView.drawableDepthFormat = GLKViewDrawableDepthFormat.format24
        
        /*
         你的OpenGL上下文的另一个可选的缓冲区是stencil（模板）缓冲区。它帮助你把绘制区
         域限定到屏幕的一个特定部分。它还用于像影子一类的事物=比如你可以使用stencil缓冲
         区确保影子投射到地板。缺省值是GLKViewDrawableStencilFormatNone，
         意思是没有stencil缓冲区，但是你可以通过设置其值为GLKViewDrawableStencilFormat8
         （唯一的其他选项）使能它
         */
        // view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
        
        //启用多重采样
        /*
         这是你可以设置的最后一个可选缓冲区，对应的GLKView属性是multisampling。
         如果你曾经尝试过使用OpenGL画线并关注过"锯齿壮线"，multisampling就可以帮助你处理
         以前对于每个像素，都会调用一次fragment shader（片段着色器），
         drawableMultisample基本上替代了这个工作，它将一个像素分成更小的单元，
         并在更细微的层面上多次调用fragment shader。之后它将返回的颜色合并，
         生成更光滑的几何边缘效果。
         要小心此操作，因为它需要占用你的app的更多的处理时间和内存。
         缺省值是GLKViewDrawableMultisampleNone，但是你可以通过设置其值GLKViewDrawableMultisample4X为来使能它
         */
        //view.drawableMultisample = GLKViewDrawableMultisample4X;
        
        EAGLContext.setCurrent(context)
        glEnable(GLenum(GL_DEPTH_TEST)) //开启深度测试，就是让离你近的物体可以遮挡离你远的物体。
        glClearColor(1, 0, 0, 1.0)//设置surface的清除颜色，也就是渲染到屏幕上的背景色。
    }
    
    //2.设置上下文
    func setupContext() {
        //EAGLContext 是苹果在iOS 平台下实现的OpenGLES渲染层，用于渲染结果在目标surface上的更新。
        //1.新建上下文
        context = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        if (context == nil) {
            NSLog("Failed to load context")
        }
        
        EAGLContext.setCurrent(context)
        //开启深度测试，就是让离你近的物体可以遮挡离你远的物体。
        glEnable(GLenum(GL_DEPTH_TEST))
        
        //给glkView上下文赋值
        glkView.context = context
    }
    
    //3.设置顶点数据（位置，颜色，纹理(渲染图片时用到)）
    func setupVertexData() {
        //不压缩
//        let image = UIImage(named: "cTest.jpg")!
//        let realRect = AVMakeRect(aspectRatio: image.size, insideRect: self.view.bounds)
//        let widthRatio: Float = Float(realRect.size.width/self.view.bounds.size.width)
//        let heightRatio: Float = Float(realRect.size.height/self.view.bounds.size.height)
//
//        let vertexArray: [GLfloat] = [
//            //位置：（x, y, z）  颜色：（r, g, b）  纹理：（s, t）
//            widthRatio,  -heightRatio, 0.0,    1.0, 0.0, 0.0,    1.0, 0.0, //右下
//            widthRatio,  heightRatio, 0.0,     1.0, 0.0, 0.0,    1.0, 1.0, //右上
//            -widthRatio, heightRatio, 0.0,    1.0, 0.0, 0.0,    0.0, 1.0, //左上
//
//            widthRatio,  -heightRatio, 0.0,    0.0, 1.0, 0.0,    1.0, 0.0, //右下
//            -widthRatio, heightRatio, 0.0,    0.0, 1.0, 0.0,    0.0, 1.0, //左上
//            -widthRatio, -heightRatio, 0.0,   0.0, 1.0, 0.0,    0.0, 0.0  //左下
//        ]
        
        //第一步：设置顶点数组
        //OpenGL ES的世界坐标系是[-1, 1]，故而点(0, 0)是在屏幕的正中间。
        //顶点数据，前3个是顶点坐标x,y,z；后面2个是纹理坐标。
        //纹理坐标系的取值范围是[0, 1]，原点是在左下角。故而点(0, 0)在左下角，点(1, 1)在右上角
        //2个三角形构成
        let vertexArray: [GLfloat] = [
            //位置：（x, y, z）  颜色：（r, g, b）  纹理：（s, t）
            0.5, -0.5, 0.0,    1.0, 0.0, 0.0,    1.0, 0.0, //右下
            0.5, 0.5, 0.0,     1.0, 0.0, 0.0,    1.0, 1.0, //右上
            -0.5, 0.5, 0.0,    1.0, 0.0, 0.0,    0.0, 1.0, //左上

            0.5, -0.5, 0.0,    0.0, 1.0, 0.0,    1.0, 0.0, //右下
            -0.5, 0.5, 0.0,    0.0, 1.0, 0.0,    0.0, 1.0, //左上
            -0.5, -0.5, 0.0,   0.0, 1.0, 0.0,    0.0, 0.0  //左下
        ]
        
        //第二：步开启顶点缓冲区
        //顶点缓存区
        var buffer: GLuint = GLuint()
        //申请一个缓存区标识符
        glGenBuffers(1, &buffer)
        //glBindBuffer把标识符绑定到GL_ARRAY_BUFFER上
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        //glBufferData把顶点数据从cpu内存复制到gpu内存
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * vertexArray.count, vertexArray, GLenum(GL_STATIC_DRAW))
        
        //第三步：设置合适的格式从buffer里面读取数据）
        /*
         默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的，意味着数据在着色器端是不可见的，哪怕数据已经上传到GPU，由glEnableVertexAttribArray启用指定属性，才可在顶点着色器中访问逐顶点的属性数据。glVertexAttribPointer或VBO只是建立CPU和GPU之间的逻辑连接，从而实现了CPU数据上传至GPU。但是，数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
         */
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        
        
        //glVertexAttribPointer 使用来上传顶点数据到GPU的方法（设置合适的格式从buffer里面读取数据）
        // index: 指定要修改的顶点属性的索引值
        // size : 指定每个顶点属性的组件数量。必须为1、2、3或者4。初始值为4。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a））
        // type : 指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
        // normalized : 指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
        // stride : 指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
        // ptr    : 指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0 这个值受到VBO的影响
        
        /*
         VBO,顶点缓存对象
         在不使用VBO的情况下：事情是这样的，ptr就是一个指针，指向的是需要上传到顶点数据指针。通常是数组名的偏移量。
         
         在使用VBO的情况下：首先要glBindBuffer，以后ptr指向的就不是具体的数据了。因为数据已经缓存在缓冲区了。这里的ptr指向的是缓冲区数据的偏移量。这里的偏移量是整型，但是需要强制转换为const GLvoid *类型传入。注意的是，这里的偏移的意思是数据个数总宽度数值。
         
         比如说：这里存放的数据前面有3个float类型数据，那么这里的偏移就是，3*sizeof(float).
         
         最后解释一下，glVertexAttribPointer的工作原理：
         首先，通过index得到着色器对应的变量openGL会把数据复制给着色器的变量。
         以后，通过size和type知道当前数据什么类型，有几个。openGL会映射到float，vec2, vec3 等等。
         由于每次上传的顶点数据不止一个，可能是一次4，5，6顶点数据。那么通过stride就是在数组中间隔多少byte字节拿到下个顶点此类型数据。
         最后，通过ptr的指针在迭代中获得所有数据。
         那么，最最后openGL如何知道ptr指向的数组有多长，读取几次呢。是的，openGL不知道。所以在调用绘制的时候，需要传入一个count数值，就是告诉openGL绘制的时候迭代几次glVertexAttribPointer调用。
         */
        
        //(GLfloat *)NULL + 0 指针，指向数组首地址
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 0))
        
        //顶点颜色
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.color.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.color.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 3))

        //纹理
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        //(GLfloat *)NULL + 3,指向到纹理数据
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size * 6))
    }
    
    //4.设置着色器：顶点着色器和片元着色器 (苹果GLKit已经将这两个着色器封装了)
    func setupEffect() {
        //着色器
        myEffect = GLKBaseEffect()
    }
    
    //5.加载纹理
    func setupTexture() {
        //第一步，获取纹理图片保存路径
        let filePath = Bundle.main.path(forResource: "cTest", ofType: "jpg")
        //GLKTextureLoaderOriginBottomLeft,纹理坐标是相反的
        let options: [String : NSNumber] = [GLKTextureLoaderOriginBottomLeft : 1]
        let textureInfo: GLKTextureInfo = try! GLKTextureLoader.texture(withContentsOfFile: filePath!, options: options)
        
        //第一个纹理属性
        myEffect.texture2d0.enabled = GLboolean(GL_TRUE)
        //纹理的名字
        myEffect.texture2d0.name = textureInfo.name
    }
    
}

//MARK: - GLKViewDelegate
extension ViewController {
    //6.绘制渲染
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        //设置surface的清除颜色，也就是渲染到屏幕上的背景色。
        glClearColor(0, 0, 1.0, 1.0)
        //清除surface内容，恢复至初始状态
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        //启动着色器
        myEffect.prepareToDraw()
        
        /*
         定义：
         void glDrawArrays(  GLenum mode,    GLint first,    GLsizei count);
         
         参数：
         mode：
             需要渲染的图元类型，包括 GL_POINTS, GL_LINE_STRIP, GL_LINE_LOOP, GL_LINES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN ，GL_TRIANGLES。
         
         first：
             从数组缓存中的哪一位开始绘制，一般为0.

         count：
             数组中顶点的数量.
         */
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
    }
    
    
}
