precision mediump float; //通过precision关键字来指定默认精度，这样就不用每一个变量前面都声明精度限定符了
varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标

//BGRA
// 灰度图像转换的709亮度值
const vec3 kRec709Luma = vec3(0.213, 0.715, 0.072);


uniform sampler2D colorMap; //纹理

void main()
{
    vec4 outColor = texture2D(colorMap, vec2(varyTextCoord.x,varyTextCoord.y));
//    float grayColor = dot(outColor.rgb, kRec709Luma);
    gl_FragColor = vec4(vec3(outColor.rgb), 1.0);
}
