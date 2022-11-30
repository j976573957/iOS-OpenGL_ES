attribute vec4 position; //顶点数据
attribute vec2 textCoordinate; //纹理坐标
uniform mat4 rotateMatrix; //旋转矩阵
varying lowp vec2 varyTextCoord; //传递给片元着色器纹理坐标

void main()
{
    varyTextCoord = textCoordinate;
    
    vec4 vPos = position;
    vPos = vPos * rotateMatrix;
    gl_Position = vPos;
}
