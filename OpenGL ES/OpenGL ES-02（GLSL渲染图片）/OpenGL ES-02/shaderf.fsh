varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标

uniform sampler2D colorMap; //纹理


void main()
{
    gl_FragColor = texture2D(colorMap, varyTextCoord);
}
