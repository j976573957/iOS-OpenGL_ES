precision mediump float; //通过precision关键字来指定默认精度，这样就不用每一个变量前面都声明精度限定符了
// 灰度图像转换的709亮度值
const vec3 kRec709Luma = vec3(0.213, 0.715, 0.072);

varying lowp vec2 varyTextCoord; //顶点着色器传递过来的纹理坐标

uniform sampler2D colorMap; //纹理

void main()
{
    vec4 outColor = texture2D(colorMap, varyTextCoord);
    float grayColor = dot(outColor.rgb, kRec709Luma);
    gl_FragColor = vec4(vec3(grayColor), 1.0);
    
    //仅取绿色: 将RGB全部设置为G，即GRB全部取绿色值
//    gl_FragColor = vec4(outColor.g, outColor.g, outColor.g, 1.0);
}
