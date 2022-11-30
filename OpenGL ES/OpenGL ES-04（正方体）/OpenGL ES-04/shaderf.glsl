varying lowp vec4 varyColor; //顶点颜色
varying lowp vec3 varyTextCoord; //顶点着色器传递过来的纹理坐标

//uniform sampler2D colorMap; //纹理
uniform samplerCube us2d_texture;

void main()
{
    gl_FragColor = textureCube(us2d_texture, varyTextCoord) * varyColor;
}

