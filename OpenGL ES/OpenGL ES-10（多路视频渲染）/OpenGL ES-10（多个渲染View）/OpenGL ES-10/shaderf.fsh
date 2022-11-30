precision mediump float; //通过precision关键字来指定默认精度，这样就不用每一个变量前面都声明精度限定符了
// 灰度图像转换的709亮度值
const vec4 kRec709Luma = vec4(0.213, 0.715, 0.072, 1.0);

varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标

uniform sampler2D texture1; //纹理1

void main()
{
    vec2 uv = varyTextCoord.xy;
    gl_FragColor = texture2D(texture1, uv);
}


