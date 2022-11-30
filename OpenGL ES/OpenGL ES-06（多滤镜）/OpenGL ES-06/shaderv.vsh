attribute vec4 position; //顶点数据
attribute vec2 inputTextureCoordinate; //纹理坐标
//uniform mat4 rotateMatrix; //旋转矩阵
varying lowp vec2 textureCoordinate; //传递给片元着色器纹理坐标

void main()
{
    textureCoordinate = inputTextureCoordinate;
    
    vec4 vPos = position;
//    vPos = vPos * rotateMatrix;
    gl_Position = vPos;
}
