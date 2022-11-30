precision mediump float; //通过precision关键字来指定默认精度，这样就不用每一个变量前面都声明精度限定符了
//// 灰度图像转换的709亮度值
//const vec3 kRec709Luma = vec3(0.213, 0.715, 0.072);
//
varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标
//
//uniform sampler2D colorMap; //纹理
//
//void main()
//{
//    vec4 outColor = texture2D(colorMap, vec2(varyTextCoord.x,1.0-varyTextCoord.y));
//    float grayColor = dot(outColor.rgb, kRec709Luma);
//    gl_FragColor = vec4(vec3(grayColor), 1.0);
//}


uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;
uniform mat3 colorConversionMatrix;

void main()
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    // Subtract constants to map the video range start at 0
    yuv.x = (texture2D(SamplerY, varyTextCoord).r);// - (16.0/255.0));
    yuv.yz = (texture2D(SamplerUV, varyTextCoord).ra - vec2(0.5, 0.5));
    
    rgb = colorConversionMatrix * yuv;

    gl_FragColor = vec4(rgb, 1);
}


/*
 shader是根据传入format的不同，转化方式不同。注意下面几点：

 y的纹理大小和视频帧的宽高一致，但uv的大小是y的1/2，但纹理会插值缩放到与y一样的大小
 在获取u、v的数据时候，需 减去0.5 ， 因为 uv的数据取值返回是 从 -100多到正100多，最后传入shader中会 归一化到0-1，因此，为了正确转化为rgb，需要将uv归一化到 -0.5 到 0.5 与原来的 rgb对应一样。
 ————————————————
 版权声明：本文为CSDN博主「Lammyzp」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
 原文链接：https://blog.csdn.net/zhangpengzp/article/details/89532590
 
 */
