attribute vec4 position; //顶点数据
attribute vec2 textCoordinate; //纹理坐标
varying lowp vec2 varyTextCoord; //传递给片元着色器纹理坐标

void main()
{
    varyTextCoord = vec2(textCoordinate.x, 1.0-textCoordinate.y);
    
    vec4 vPos = position;
    gl_Position = vPos;
}
