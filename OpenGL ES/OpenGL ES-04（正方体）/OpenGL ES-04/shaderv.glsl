attribute vec4 position;
attribute vec4 positionColor; //顶点颜色
attribute vec3 textCoordinate; //纹理坐标
uniform mat4 projectionMatrix; //投影矩阵
uniform mat4 modelViewMatrix;  //模型视图矩阵

varying lowp vec4 varyColor; //顶点颜色
varying lowp vec3 varyTextCoord; //传递给片元着色器纹理坐标

void main()
{
    varyColor = positionColor;
    varyTextCoord = textCoordinate;
    
    vec4 vPos;
    vPos = projectionMatrix * modelViewMatrix * position;
    gl_Position = vPos;
}
