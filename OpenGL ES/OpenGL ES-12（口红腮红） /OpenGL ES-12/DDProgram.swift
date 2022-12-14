//
//  DDProgram.swift
//  OpenGL ES-12
//
//  Created by Mac on 2022/11/23.
//

import Foundation

class DDProgram {
    
    var program: GLuint = 0
    
    init(_ vertShaderPath: String, _ fragShaderPath: String) {
        self.program = compileAndLinkShader(vertShaderPath, fragShaderPath)
    }
    
    //5.2 链接着色器（shader）
    private func compileAndLinkShader(_ vertShaderName: String, _ fragShaderName: String) -> GLuint {
        //1. 创建program
        let program: GLuint = glCreateProgram()
        
        //2. 编译顶点着色器程序、片元着色器程序
        let vertShader = compileShader(shaderName: vertShaderName, shaderType: GLenum(GL_VERTEX_SHADER))
        let fragShader = compileShader(shaderName: fragShaderName, shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        //3. 把着色器绑定到最终的程序
        glAttachShader(program, vertShader)
        glAttachShader(program, fragShader)
        
        //释放不需要的shader
        glDeleteShader(vertShader)
        glDeleteShader(fragShader)
        
        //4.链接
        glLinkProgram(program)
        var linkStatus: GLint = 0
        //获取链接状态
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            NSLog("link error")
            let message = UnsafeMutablePointer<GLchar>.allocate(capacity: 512)
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.size * 512), nil, message)
            let str = String(utf8String: message)
            print("error = \(str ?? "没获取到错误信息")")
            return 0
        }
        
        NSLog("Program link success! --> \(fragShaderName)")
        
        return program
    }
    
    //5.1 编译着色器（shader）
    private func compileShader(shaderName: String, shaderType: GLenum) -> GLuint {
        
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
    
}
